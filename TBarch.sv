//test bench architecture:


//packet

class packet;
rand bit [3:0]a,b;
bit [3:0]sum;
bit cout;
endclass

//interface
interface intf();
bit [3:0]a,b,sum;
bit cout;
endinterface

//generator

class generator;
packet pkt;
mailbox #(packet)gen_drv;
function new(mailbox #(packet)gen_drv);
this.gen_drv=gen_drv;
endfunction

task run();
pkt=new();
if(pkt.randomize())
gen_drv.put(pkt);
else
$display("field");
endtask
endclass

//driver

class driver;
packet pkt;
mailbox #(packet)gen_drv;
mailbox #(packet)drv_sb;
virtual intf i;
function new(mailbox #(packet)gen_drv,mailbox #(packet)drv_sb,virtual intf i);
this.gen_drv=gen_drv;
this.drv_sb=drv_sb;
this.i=i;
endfunction

task run();
gen_drv.get(pkt);
drv_sb.put(pkt);
i.a=pkt.a;
i.b=pkt.b;
endtask
endclass

//monitor

class monitor;
packet pkt=new();
mailbox #(packet)mon_sb;
virtual intf i;
function new(mailbox #(packet)mon_sb,virtual intf i);
this.mon_sb=mon_sb;
this.i=i;
endfunction
task run();
pkt.a=i.a;
pkt.b=i.b;
pkt.sum=i.sum;
pkt.cout=i.cout;
mon_sb.put(pkt);
endtask
endclass


//scoreboard

class scoreboard;
packet pkt1,pkt2;
mailbox #(packet)drv_sb;
mailbox #(packet)mon_sb;

function new(mailbox #(packet)drv_sb,mailbox #(packet)mon_sb);

this.drv_sb=drv_sb;
this.mon_sb=mon_sb;
endfunction
task run;
drv_sb.get(pkt1);
mon_sb.get(pkt2);

{pkt1.cout,pkt1.sum}=pkt1.a+pkt1.b;

if(pkt1.cout==pkt2.cout&&pkt1.sum==pkt2.sum)
$display("pkt1:\t%d,%d,%d,%d,pkt2:\t%d,%d,%d,%d",pkt1.a,pkt1.b,pkt1.sum,pkt1.cout,pkt1.a,pkt1.b,pkt1.sum,pkt1.cout);
else
$display("miss");
endtask
endclass

//environment

class environment;
mailbox #(packet)gen_drv;
mailbox #(packet)drv_sb;
mailbox #(packet)mon_sb;

generator g1;
driver d1;
monitor m1;
scoreboard s1;
virtual intf i;

function new(virtual intf i);
this.i=i;
endfunction

function build();
gen_drv=new();
drv_sb=new();
mon_sb=new();
g1=new(gen_drv);
d1=new(gen_drv,drv_sb,i);
m1=new(mon_sb,i);
s1=new(drv_sb,mon_sb);
endfunction

task run();
g1.run();
d1.run();
#1 m1.run();
s1.run();
endtask
endclass



//DUT

module adder
(input [3:0]a,b,output [3:0]sum,output cout);
assign {cout,sum}=a+b;
endmodule

//test

module test(intf i);
environment en;
initial
begin
en=new(i);
en.build();
repeat(100)
en.run();
end
endmodule


///top_testbench

module top();
intf i();
adder a1(.a(i.a),.b(i.b),.sum(i.sum),.cout(i.cout));
test t1(.i(i));
endmodule