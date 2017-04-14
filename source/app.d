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
  import std.format;
  return q{
    auto R%s ( ) in {
      assert(val.type == typeid(%s));
    } body {
      return val.get!%s;
    }
  }.format(name[0].toUpper ~ name[1..$], name, name);
}

struct Atom {
  import std.variant;
  private Variant val;
public:
  mixin(Atom_Variant_Func_Gen!"string");
  mixin(Atom_Variant_Func_Gen!"int");
  mixin(Atom_Variant_Func_Gen!"float");

  auto RList ( ) in {
    assert(val.type == typeid(Variant[]));
  } body {
    return val;
  }
}

Atom Func_Call ( Atom func, Atom[] args ) {
  switch ( func.val ) {
    default:
      return Atom("UNKNOWN FUNC: " ~ func.val);
    case "+":
      return Atom(args[0].val ~ args[1].val);
  }
}

Atom Eval ( ParseTree expr ) {
  import std.algorithm, std.array;
  writeln("RECEIVED: ", expr);
  foreach ( ref atom; expr.children ) {
    writeln("NOW: ", atom);
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
        return Atom(atom.matches[0]);
      case "AOQ.FloatL":
        return Atom(atom.matches[0]);
      case "AOQ.SExpr":
        auto func = atom.children[0].Eval;
        auto args = atom.children[1 .. $].map!(Eval).array;
        writeln("FUNC: ", atom.children[0]);
        writeln("FUNC: ", func);
        return Func_Call ( func, args );
        // writeln("FUNC: ", atom.children[0]);
        // writeln("ARGS: ", atom.children[1 .. $]);
        // foreach ( ref sexpr; atom.children ) {
        //   writeln("SEXPR: ", sexpr);
        // }
        // writeln("---");
        // Atom func = atom.children[0].Eval;
        // writeln("CHILD: ", atom.children[0].input);
        // auto args = atom.children[1 .. $].map!(Eval).array;
        // writeln("SIZE: ", atom.children.length);
        // writeln("FUNC: ", func, " ARGS: ", args);
      // break;
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

void main() {
  "(+ 1 2)".Evaluate.writeln;
  // "(+ '(1 2.0f) somevar)".Evaluate.writeln;
}
