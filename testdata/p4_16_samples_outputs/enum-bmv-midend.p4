#include <core.p4>
#include <v1model.p4>

header hdr {
    bit<32> a;
    bit<32> b;
    bit<32> c;
}

enum Choice {
    First,
    Second
}

struct Headers {
    hdr h;
}

struct Meta {
}

parser p(packet_in b, out Headers h, inout Meta m, inout standard_metadata_t sm) {
    state start {
        b.extract<hdr>(h.h);
        transition accept;
    }
}

control vrfy(in Headers h, inout Meta m) {
    apply {
    }
}

control update(inout Headers h, inout Meta m) {
    apply {
    }
}

control egress(inout Headers h, inout Meta m, inout standard_metadata_t sm) {
    apply {
    }
}

control deparser(packet_out b, in Headers h) {
    apply {
        b.emit<hdr>(h.h);
    }
}

control ingress(inout Headers h, inout Meta m, inout standard_metadata_t sm) {
    @name("h_0") hdr h_1;
    @name("c") Choice c_1;
    @name("tmp") bool tmp_0;
    action act() {
        h_1.c = h_1.a;
    }
    action act_0() {
        h_1.c = h_1.b;
    }
    action act_1() {
        h_1 = h.h;
        c_1 = Choice.First;
        tmp_0 = c_1 == Choice.Second;
    }
    action act_2() {
        h.h = h_1;
        sm.egress_spec = 9w0;
    }
    table tbl_act() {
        actions = {
            act_1();
        }
        const default_action = act_1();
    }
    table tbl_act_0() {
        actions = {
            act();
        }
        const default_action = act();
    }
    table tbl_act_1() {
        actions = {
            act_0();
        }
        const default_action = act_0();
    }
    table tbl_act_2() {
        actions = {
            act_2();
        }
        const default_action = act_2();
    }
    apply {
        tbl_act.apply();
        if (tmp_0) 
            tbl_act_0.apply();
        else 
            tbl_act_1.apply();
        tbl_act_2.apply();
    }
}

V1Switch<Headers, Meta>(p(), vrfy(), ingress(), egress(), update(), deparser()) main;
