#include <core.p4>

typedef bit<9> PortIdUInt_t;
typedef bit<9> PortId_t;
typedef bit<32> PortIdInHeader_t;
match_kind {
    range,
    selector
}

@metadata @name("standard_metadata") struct standard_metadata_t {
    PortId_t ingress_port;
    PortId_t egress_spec;
    PortId_t egress_port;
    bit<32>  clone_spec;
    bit<32>  instance_type;
    bit<32>  packet_length;
    @alias("queueing_metadata.enq_timestamp") 
    bit<32>  enq_timestamp;
    @alias("queueing_metadata.enq_qdepth") 
    bit<19>  enq_qdepth;
    @alias("queueing_metadata.deq_timedelta") 
    bit<32>  deq_timedelta;
    @alias("queueing_metadata.deq_qdepth") 
    bit<19>  deq_qdepth;
    @alias("intrinsic_metadata.ingress_global_timestamp") 
    bit<48>  ingress_global_timestamp;
    @alias("intrinsic_metadata.egress_global_timestamp") 
    bit<48>  egress_global_timestamp;
    @alias("intrinsic_metadata.lf_field_list") 
    bit<32>  lf_field_list;
    @alias("intrinsic_metadata.mcast_grp") 
    bit<16>  mcast_grp;
    @alias("intrinsic_metadata.resubmit_flag") 
    bit<32>  resubmit_flag;
    @alias("intrinsic_metadata.egress_rid") 
    bit<16>  egress_rid;
    bit<1>   checksum_error;
    @alias("intrinsic_metadata.recirculate_flag") 
    bit<32>  recirculate_flag;
}

enum CounterType {
    packets,
    bytes,
    packets_and_bytes
}

enum MeterType {
    packets,
    bytes
}

extern counter {
    counter(bit<32> size, CounterType type);
    void count(in bit<32> index);
}

extern direct_counter {
    direct_counter(CounterType type);
    void count();
}

extern meter {
    meter(bit<32> size, MeterType type);
    void execute_meter<T>(in bit<32> index, out T result);
}

extern direct_meter<T> {
    direct_meter(MeterType type);
    void read(out T result);
}

extern register<T> {
    register(bit<32> size);
    void read(out T result, in bit<32> index);
    void write(in bit<32> index, in T value);
}

extern action_profile {
    action_profile(bit<32> size);
}

enum HashAlgorithm {
    crc32,
    crc32_custom,
    crc16,
    crc16_custom,
    random,
    identity,
    csum16,
    xor16
}

extern void mark_to_drop();
extern action_selector {
    action_selector(HashAlgorithm algorithm, bit<32> size, bit<32> outputWidth);
}

@deprecated("Please use verify_checksum/update_checksum instead.") extern Checksum16 {
    Checksum16();
    bit<16> get<D>(in D data);
}

parser Parser<H, M>(packet_in b, out H parsedHdr, inout M meta, inout standard_metadata_t standard_metadata);
control VerifyChecksum<H, M>(inout H hdr, inout M meta);
@pipeline control Ingress<H, M>(inout H hdr, inout M meta, inout standard_metadata_t standard_metadata);
@pipeline control Egress<H, M>(inout H hdr, inout M meta, inout standard_metadata_t standard_metadata);
control ComputeChecksum<H, M>(inout H hdr, inout M meta);
@deparser control Deparser<H>(packet_out b, in H hdr);
package V1Switch<H, M>(Parser<H, M> p, VerifyChecksum<H, M> vr, Ingress<H, M> ig, Egress<H, M> eg, ComputeChecksum<H, M> ck, Deparser<H> dep);
header ethernet_t {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> etherType;
}

header ipv4_t {
    bit<4>  version;
    bit<4>  ihl;
    bit<8>  diffserv;
    bit<16> totalLen;
    bit<16> identification;
    bit<3>  flags;
    bit<13> fragOffset;
    bit<8>  ttl;
    bit<8>  protocol;
    bit<16> hdrChecksum;
    bit<32> srcAddr;
    bit<32> dstAddr;
}

@controller_header("packet_in") header packet_in_header_t {
    PortIdInHeader_t ingress_port;
}

@controller_header("packet_out") header packet_out_header_t {
    PortIdInHeader_t egress_port;
}

struct parsed_headers_t {
    packet_in_header_t  packet_in;
    packet_out_header_t packet_out;
    ethernet_t          ethernet;
    ipv4_t              ipv4;
}

struct fabric_metadata_t {
}

parser FabricParser(packet_in packet, out parsed_headers_t hdr, inout fabric_metadata_t meta, inout standard_metadata_t standard_metadata) {
    state start {
        transition accept;
    }
}

control FabricIngress(inout parsed_headers_t hdr, inout fabric_metadata_t fabric_metadata, inout standard_metadata_t standard_metadata) {
    bool hasExited;
    @name(".drop") action drop() {
        mark_to_drop();
    }
    @name(".drop") action drop_0() {
        mark_to_drop();
    }
    @name(".nop") action nop() {
    }
    @name(".NoAction") action NoAction_0() {
    }
    @name(".NoAction") action NoAction_3() {
    }
    @name("FabricIngress.filtering.t") table filtering_t_0 {
        key = {
            standard_metadata.ingress_port: exact @name("standard_metadata.ingress_port") ;
        }
        actions = {
            drop();
            nop();
            @defaultonly NoAction_0();
        }
        default_action = NoAction_0();
    }
    @name("FabricIngress.forwarding.fwd") action forwarding_fwd(PortId_t next_port) {
        standard_metadata.egress_spec = next_port;
    }
    @name("FabricIngress.forwarding.t") table forwarding_t_0 {
        key = {
            hdr.ipv4.dstAddr: exact @name("hdr.ipv4.dstAddr") ;
        }
        actions = {
            drop_0();
            forwarding_fwd();
            @defaultonly NoAction_3();
        }
        default_action = NoAction_3();
    }
    @hidden action act() {
        standard_metadata.egress_spec = (PortIdUInt_t)(bit<32>)hdr.packet_out.egress_port;
        hdr.packet_out.setInvalid();
        hasExited = true;
    }
    @hidden action act_0() {
        hasExited = false;
    }
    @hidden action act_1() {
        standard_metadata.egress_spec = (PortIdUInt_t)standard_metadata.egress_spec + 9w1;
        standard_metadata.egress_spec = (PortIdUInt_t)standard_metadata.egress_spec & 9w0xf;
    }
    @hidden table tbl_act {
        actions = {
            act_0();
        }
        const default_action = act_0();
    }
    @hidden table tbl_act_0 {
        actions = {
            act();
        }
        const default_action = act();
    }
    @hidden table tbl_act_1 {
        actions = {
            act_1();
        }
        const default_action = act_1();
    }
    apply {
        tbl_act.apply();
        if (hdr.packet_out.isValid()) {
            tbl_act_0.apply();
        }
        if (!hasExited) {
            filtering_t_0.apply();
            forwarding_t_0.apply();
            tbl_act_1.apply();
        }
    }
}

control FabricEgress(inout parsed_headers_t hdr, inout fabric_metadata_t fabric_metadata, inout standard_metadata_t standard_metadata) {
    @hidden action act_2() {
        hdr.packet_in.setValid();
        hdr.packet_in.ingress_port = (bit<32>)(PortIdUInt_t)standard_metadata.ingress_port;
    }
    @hidden table tbl_act_2 {
        actions = {
            act_2();
        }
        const default_action = act_2();
    }
    apply {
        if (standard_metadata.egress_port == 9w192) {
            tbl_act_2.apply();
        }
    }
}

control FabricDeparser(packet_out packet, in parsed_headers_t hdr) {
    apply {
    }
}

control FabricVerifyChecksum(inout parsed_headers_t hdr, inout fabric_metadata_t meta) {
    apply {
    }
}

control FabricComputeChecksum(inout parsed_headers_t hdr, inout fabric_metadata_t meta) {
    apply {
    }
}

V1Switch<parsed_headers_t, fabric_metadata_t>(FabricParser(), FabricVerifyChecksum(), FabricIngress(), FabricEgress(), FabricComputeChecksum(), FabricDeparser()) main;

