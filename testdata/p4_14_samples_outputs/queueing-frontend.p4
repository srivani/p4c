#include <core.p4>
#include <v1model.p4>

@name("queueing_metadata_t") struct queueing_metadata_t_0 {
    bit<48> enq_timestamp;
    bit<24> enq_qdepth;
    bit<32> deq_timedelta;
    bit<24> deq_qdepth;
}

header hdr1_t {
    bit<8> f1;
    bit<8> f2;
}

header queueing_metadata_t {
    bit<48> enq_timestamp;
    bit<24> enq_qdepth;
    bit<32> deq_timedelta;
    bit<24> deq_qdepth;
}

struct metadata {
    @name("queueing_metadata") 
    queueing_metadata_t_0 queueing_metadata;
}

struct headers {
    @name("hdr1") 
    hdr1_t              hdr1;
    @name("queueing_hdr") 
    queueing_metadata_t queueing_hdr;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name("queueing_dummy") state queueing_dummy {
        packet.extract<queueing_metadata_t>(hdr.queueing_hdr);
        transition accept;
    }
    @name("start") state start {
        packet.extract<hdr1_t>(hdr.hdr1);
        transition select(standard_metadata.packet_length) {
            32w0: queueing_dummy;
            default: accept;
        }
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name("copy_queueing_data") action copy_queueing_data_0() {
        hdr.queueing_hdr.setValid();
        hdr.queueing_hdr.enq_timestamp = meta.queueing_metadata.enq_timestamp;
        hdr.queueing_hdr.enq_qdepth = meta.queueing_metadata.enq_qdepth;
        hdr.queueing_hdr.deq_timedelta = meta.queueing_metadata.deq_timedelta;
        hdr.queueing_hdr.deq_qdepth = meta.queueing_metadata.deq_qdepth;
    }
    @name("t_egress") table t_egress_0() {
        actions = {
            copy_queueing_data_0();
            NoAction();
        }
        default_action = NoAction();
    }
    apply {
        t_egress_0.apply();
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name("set_port") action set_port_0(bit<9> port) {
        standard_metadata.egress_spec = port;
    }
    @name("_drop") action _drop_0() {
        mark_to_drop();
    }
    @name("t_ingress") table t_ingress_0() {
        actions = {
            set_port_0();
            _drop_0();
            NoAction();
        }
        key = {
            hdr.hdr1.f1: exact;
        }
        size = 128;
        default_action = NoAction();
    }
    apply {
        t_ingress_0.apply();
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit<hdr1_t>(hdr.hdr1);
        packet.emit<queueing_metadata_t>(hdr.queueing_hdr);
    }
}

control verifyChecksum(in headers hdr, inout metadata meta) {
    apply {
    }
}

control computeChecksum(inout headers hdr, inout metadata meta) {
    apply {
    }
}

V1Switch<headers, metadata>(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;
