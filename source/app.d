import std.stdio;
import pegged.grammar;

mixin(grammar(`
  AOQ:
    SExpr < "(" (Atom/SExpr)+ ")"

    Sign < "-"
    Integer <- digit+
    IntegerL <- Sign? Integer
    FloatL <- IntegerL "." Integer "f"
    List < "'(" (Atom / SExpr / List)* ")"

    Atom <- FloatL / IntegerL / Variable / List / Operator

    Comment < "//" (!endOfLine .)* endOfLine

    Variable <- (alpha / Alpha / Operator)+
    Operator < "+" / "-" / "*" / "/" / "<" / ">" / ">=" / "<=" / "=" / "_"
`));

string Atom_Variant_Func_Gen ( string name ) {
  import std.format, std.conv, std.string : toUpper;
  return q{
    auto R%s ( ) in {
      assert(val.type == typeid(%s), "Trying to use type " ~ val.type.to!string ~ " as %s");
    } body {
      return val.get!%s;
    }

    this ( %s val_ ) {
      val = val_;
    }
  }.format(name[0].toUpper.to!string ~ name[1..$], name, name, name, name);
}

struct Atom {
  import std.variant;
  private Variant val;
  mixin(Atom_Variant_Func_Gen("string") );
  mixin(Atom_Variant_Func_Gen("float" ) );
  mixin(Atom_Variant_Func_Gen("int"   ) );

  auto RList ( ) in {
    assert(val.type == typeid(Variant[]));
  } body {
    return val;
  }

  auto RType ( ) { return val.type; }
}

Atom Func_Call ( Atom func, Atom[] args ) {
  auto fn_name = func.RString;
  switch ( fn_name ) {
    default:
      return Atom("UNKNOWN FUNC: " ~ fn_name);
    case "+":
      if ( args[0].RType == typeid(int) )
        return Atom(args[0].RInt + args[1].RInt);
      return Atom(args[0].RFloat + args[1].RFloat);
  }
}

Atom Eval ( ParseTree expr ) {
  import std.algorithm, std.array, std.conv : to;
  foreach ( ref atom; expr.children ) {
    switch ( atom.name ) {
      default:
        assert(false, "Unknown atom name: " ~ atom.name);
      case "AOQ.Atom":
        return Eval(atom.children[0]);
      case "AOQ.Variable":
        return Atom(atom.matches[0]);
      case "AOQ.Operator":
        return Atom(atom.matches[0]);
      case "AOQ.IntegerL":
        return Atom(atom.matches[0].to!int);
      case "AOQ.FloatL":
        auto m = atom.matches[0..$];
        if ( m[$-1] == "f" ) m = m[0 .. $-1];
        return Atom(m.joiner.array.to!float);
      case "AOQ.SExpr":
        auto func = atom.children[0].Eval;
        auto args = atom.children[1 .. $].map!(Eval).array;
        writeln("ARGS: ", args);
        return Func_Call ( func, args );
    }
  }
  return Atom("");
}

auto Evaluate ( string str_expression ) {
  auto expression = AOQ(str_expression);
  writeln(expression);
  writeln("---");
  return expression.Eval;
}

unittest {
  // ints   ---
  assert("(+ 1 2)".Evaluate.RInt() == 3);
  // floats ---
  assert("(+ 1.5f 2.0f)".Evaluate.RFloat() == 3.5f);
  // sexprs ---
  // assert("(+ (+ 1 2) (+ (+ 3 4) 5))".Evaluate.RInt() == 1+2+3+4+5);
}

void main() {
  "(+ 1.5f 2.0f)".Evaluate.writeln(" RESULT");
  // "(+ '(1 2.0f) somevar)".Evaluate.writeln;
}
