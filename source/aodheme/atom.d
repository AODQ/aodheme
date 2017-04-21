module atom;
import functions;

string Atom_Variant_Func_Gen ( string name ) {
  import std.format, std.conv, std.string : toUpper;
  return q{
    auto R%s ( ) in {
      // assert(val.type == typeid(%s) && val.type != typeid(string),
      //           "Trying to use type " ~ val.type.to!string ~ " as %s");
    } body {
      return val.get!(%s);//.to!(%s);
    }

    this ( %s val_ ) {
      val = val_;
    }
  }.format(name[0].toUpper.to!string ~ name[1..$], name, name, name, name,
           name);
}

struct Atom {
  import std.variant;
  private Variant val;
  mixin(Atom_Variant_Func_Gen("string") );
  mixin(Atom_Variant_Func_Gen("float" ) );
  mixin(Atom_Variant_Func_Gen("int"   ) );

  this ( Atom[] list ) {
    val = list.dup;
  }

  this ( Function func ) {
    val = func;
  }

  auto RList ( ) in {
    assert(val.type == typeid(Atom[]));
  } body {
    return val.get!(Atom[]);
  }

  auto RFunction ( ) {
    assert(val.type == typeid(Function));
    return val.get!(Function);
  }

  auto RType ( ) { return val.type; }

  auto To_String ( ) {
    import std.algorithm, std.conv : to;
    if ( val.type == typeid(string) ) return RString;
    if ( val.type == typeid(int   ) ) return RInt.to!string;
    if ( val.type == typeid(float ) ) return RFloat.to!string;
    if ( val.type == typeid(Atom[]) )
      return RList.map!(n => n.To_String).to!string;
    if ( val.type == typeid(Function) ) {
      return "Function";
    }
    assert(false);
  }
}
