module zug.util;

import std.stdio;
import std.conv;
import std.array;
import std.process;

string dumper(string[string][] all_rows) {
    string[] result;
   
    foreach (string[string] row_data; all_rows) {
	 result ~= dumper(row_data);
    }
    return result.join(",\n") ~ "\n=========================\n";
}

string dumper(string[string] data) {
    string[] result;
    foreach (string key; data.keys) {
        result ~= "  \"" ~ key ~ "\" => " ~ "\"" ~ data[key] ~ "\"";
    }    
    
    return "{\n" ~ result.join(",\n") ~ "\n}";
}

unittest {
    string expected = "{
  b => 1
  a => 1
}

{
  b => 2
  a => 2
}
";
    string dumped = dump_array_of_hashes([["a":"1","b": "1"], ["a": "2", "b":"2"]]);
    assert(expected == dumped);    
}


// TODO: this dumps the names but not the types, instead puts "string" 
void dump_array_of_structs (T)(T[] array_of_structs) {
    foreach (T item; array_of_structs) {
        auto members = __traits(allMembers, typeof(item));
        foreach (member; members) {
            stderr.writefln("%s %s", typeof(member).stringof, member );
        }
    }
}

// http://forum.dlang.org/post/gqqpl2$1ujg$1@digitalmars.com
void log(T)(T obj) {
   
  static if (is(T == struct) || is(T == class)){
     writefln("{");
     foreach(i,_;obj.tupleof) {
       writefln("    %s : %s,", obj.tupleof[i].stringof[4..$], obj.tupleof[i]);
     }
     writefln("}");
  }
  else {
     writefln(obj);
  }
}

// TODO: is it possible to make this a template ? 
void warn(string message)
{
    stderr.writeln(message);    
}

// I need a better name, D2 took "debug", but their debug is not what I need my
//    "debug" for 
void write_debug(string message)
{
    if (env_debug_enabled()) {
        stderr.writeln("DEBUG: " ~ message);
    }
}

bool env_debug_enabled() {
    string do_debug = std.process.environment.get("DEBUG");
    if (do_debug != "0" && do_debug > "") {
        return true;
    }
    return false;
}
