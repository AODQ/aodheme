import std.stdio;
import pegged.grammar;

mixin(grammar(`
  AOQ:
    Loop < (SExpr / List)+
    SExpr < "(" (Atom/SExpr)+ ")"

    Sign <- "-"
    Integer <- digit+
    IntegerL <- Sign? Integer
    FloatL <- IntegerL "." Integer "f"
    List < ("'(" (Atom / SExpr / List)* ")") / ("[" (Atom / SExpr / List)* "]")

    Atom <- FloatL / IntegerL / Variable / List / Operator

    Comment < "#" (!endOfLine .)* endOfLine

    Variable <- (alpha / Alpha) (alpha / Alpha / Operator / digit)*
    Operator <- ("+" / "-" / "*" / "/" / "<" / ">" / ">=" / "<=" / "=")+
`));

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

  auto RList ( ) in {
    assert(val.type == typeid(Atom[]));
  } body {
    return val.get!(Atom[]);
  }

  auto RType ( ) { return val.type; }

  auto To_String ( ) {
    import std.algorithm, std.conv : to;
    if ( val.type == typeid(string) ) return RString;
    if ( val.type == typeid(int   ) ) return RInt.to!string;
    if ( val.type == typeid(float ) ) return RFloat.to!string;
    if ( val.type == typeid(Atom[]) )
      return RList.map!(n => n.To_String).to!string;
    assert(false);
  }
}

Atom Func_Call ( Atom func, Atom[] args ) {
  import std.math;

  string Arith_Mix ( string mixer, int arguments = 2 ) {
    import std.format;
    string Arg_Mixer ( string value ) {
      return q{
        (args[%s].RType == typeid(int) ? args[%s].RInt : args[%s].RFloat)
      }.format(value, value, value);
    }
    if ( arguments == 1 )
      return mixer.format(Arg_Mixer("0"));
    if ( arguments == 2 )
      return mixer.format(Arg_Mixer("0"), Arg_Mixer("1"));
    assert(false);
  }

  auto fn_name = func.RString;
  switch ( fn_name ) {
    default: return Atom("UNKNOWN FUNC: " ~ fn_name);
    // --- LISP operations ---
    case "car": return args[0].RList[0];
    case "cdr": return Atom(args[0].RList[1..$]);
    case "cons": return Atom(args[0] ~ args[1].RList);
    // --- DLang mathematics ---
    case "+":    mixin(Arith_Mix(`return Atom(%s + %s);`));
    case "-":    mixin(Arith_Mix(`return Atom(%s - %s);`));
    case "*":    mixin(Arith_Mix(`return Atom(%s * %s);`));
    case "/":    mixin(Arith_Mix(`return Atom(%s / %s);`));
    case "//":   mixin(Arith_Mix(`return Atom((%s / %s).to!int);`));
    case "abs":  mixin(Arith_Mix(`return Atom(abs(%s));`, 1));
    case "sqrt": mixin(Arith_Mix(`return Atom(sqrt(%s));`, 1));
    case "cbrt": mixin(Arith_Mix(`return Atom(cbrt(%s));`, 1));
    case "hypotenuse": mixin(Arith_Mix(`return Atom(hypot(%s, %s));`));
    case "next-pow2":  mixin(Arith_Mix(`return Atom(nextPow2(%s));`, 1));
    case "sin": mixin(Arith_Mix(`return Atom(sin(%s));`, 1));
    case "cos": mixin(Arith_Mix(`return Atom(cos(%s));`, 1));
    case "tan": mixin(Arith_Mix(`return Atom(tan(%s));`, 1));
    case "asin": mixin(Arith_Mix(`return Atom(asin(%s));`, 1));
    case "acos": mixin(Arith_Mix(`return Atom(acos(%s));`, 1));
    case "atan": mixin(Arith_Mix(`return Atom(atan(%s));`, 1));
    case "atan2": mixin(Arith_Mix(`return Atom(atan2(%s, %s));`, 2));
    case "sinh": mixin(Arith_Mix(`return Atom(sinh(%s));`, 1));
    case "cosh": mixin(Arith_Mix(`return Atom(cosh(%s));`, 1));
    case "tanh": mixin(Arith_Mix(`return Atom(tanh(%s));`, 1));
    case "asinh": mixin(Arith_Mix(`return Atom(asinh(%s));`, 1));
    case "acosh": mixin(Arith_Mix(`return Atom(acosh(%s));`, 1));
    case "atanh": mixin(Arith_Mix(`return Atom(atanh(%s));`, 1));

    case "ceil": mixin(Arith_Mix(`return Atom(ceil(%s));`, 1));
    case "floor": mixin(Arith_Mix(`return Atom(floor(%s));`, 1));
    case "round": mixin(Arith_Mix(`return Atom(round(%s));`, 1));
    case "truncate": mixin(Arith_Mix(`return Atom(trunc(%s));`, 1));

    case "pow": mixin(Arith_Mix(`return Atom(pow(%s, %s));`, 2));
    case "exp": mixin(Arith_Mix(`return Atom(exp(%s));`, 1));
    case "exp2": mixin(Arith_Mix(`return Atom(exp2(%s));`, 1));
    case "expm1": mixin(Arith_Mix(`return Atom(expm1(%s));`, 1));
    case "log": mixin(Arith_Mix(`return Atom(log(%s));`, 1));
    case "log2": mixin(Arith_Mix(`return Atom(log2(%s));`, 1));
    case "log10": mixin(Arith_Mix(`return Atom(log10(%s));`, 1));
    case "logb": mixin(Arith_Mix(`return Atom(logb(%s));`, 1));
    case "log1p": mixin(Arith_Mix(`return Atom(log1p(%s));`, 1));

    case "fmod": mixin(Arith_Mix(`return Atom(fmod(%s, %s));`, 2));
    case "remainder": mixin(Arith_Mix(`return Atom(remainder(%s, %s));`, 2));

    case "approxEqual": mixin(Arith_Mix(`return Atom(approxEqual(%s, %s));`, 2));
    case "fmax": mixin(Arith_Mix(`return Atom(fmax(%s, %s));`, 2));
    case "fmin": mixin(Arith_Mix(`return Atom(fmin(%s, %s));`, 2));
    case "nextDown": mixin(Arith_Mix(`return Atom(nextDown(%s));`, 1));
    case "nextUp": mixin(Arith_Mix(`return Atom(nextUp(%s));`, 1));

    case "isNaN": mixin(Arith_Mix(`return Atom(isNaN(%s));`, 1));
  }
}

Atom RVariable ( string var ) {
  import std.math;
  switch ( var ) {
    default:           return Atom(var);
    case "TAU":        return Atom(std.math.PI*2);
	  case "E":          return Atom(std.math.E);
    case "PI":         return Atom(std.math.PI);
    case "PI-2":       return Atom(std.math.PI_2);
    case "PI-4":       return Atom(std.math.PI_4);
    case "M-1-PI":     return Atom(std.math.M_1_PI);
    case "M-2-PI":     return Atom(std.math.M_2_PI);
    case "M-2-SQRTPI": return Atom(std.math.M_2_SQRTPI);
    case "LN10":       return Atom(std.math.LN10);
    case "LN2":        return Atom(std.math.LN2);
    case "LOG2":       return Atom(std.math.LOG2);
    case "LOG2E":      return Atom(std.math.LOG2E);
    case "LOG2T":      return Atom(std.math.LOG2T);
    case "LOG10E":     return Atom(std.math.LOG10E);
    case "SQRT2":      return Atom(std.math.SQRT2);
    case "SQRT1-2":    return Atom(std.math.SQRT1_2);
  }
}

Atom List_Eval ( ParseTree[] tree ) {
  import std.algorithm, std.array;
  Atom[] list;
  foreach ( elem; tree ) {
    switch ( elem.name ) {
      default:
        list ~= Atom(elem.matches.joiner.array.to!string);
        break;
      case "AOQ.List":
        list ~= List_Eval(elem.children);
    }
  }
  return Atom(list);
}

Atom Eval ( ParseTree atom ) {
  import std.algorithm, std.array, std.conv : to;
  switch ( atom.name ) {
    default:
      assert(false, "Unknown atom name: " ~ atom.name);
    case "AOQ": case "AOQ.Loop":
      Atom result;
      foreach ( ref a_child; atom.children ) {
        result = a_child.Eval;
      }
      return result;
    case "AOQ.Atom":
      return Eval(atom.children[0]);
    case "AOQ.List":
      return List_Eval(atom.children);
    case "AOQ.Variable":
      return RVariable(atom.matches[0..$].joiner.array.to!string);
    case "AOQ.Operator":
      return Atom(atom.matches[0]);
    case "AOQ.IntegerL":
      return Atom(atom.matches[0..$].joiner.array.to!int);
    case "AOQ.FloatL":
      auto m = atom.matches[0..$];
      if ( m[$-1] == "f" ) m = m[0 .. $-1];
      return Atom(m.joiner.array.to!float);
    case "AOQ.SExpr":
      auto func = atom.children[0].Eval;
      auto args = atom.children[1 .. $].map!(Eval).array;
      writeln(func, " ", args);
      auto res = Func_Call(func, args);
      writeln("    ==> ", res);
      return res;
  }
}

string Eval ( string str_expression ) {
  auto expression = AOQ(str_expression);
  writeln("EXPR: ", expression);
  auto res = expression.Eval;
  writeln("result: ", res.To_String());
  return res.To_String();
}

float Float_Cmp ( float a, float b, float c ) {
  import std.math : abs;
  return abs(a - b) < c;
}

void main() {
  import std.conv;
  // --- integer/flots
  assert("(+ 1 2)".Eval == "3");
  assert("(+ 1.5f 2.0f)".Eval == "3.5");
  // --- parenthesis/s-exprs
  assert("(+ (+ 1 2) 3)".Eval == "6");
  assert("(+ (+ 1 2) (+ 1 2))".Eval == "6");
  assert("(- (+ (+ 0.5f (- 0.5f 0.5f)) 0.5f) (+ 0.5f 0.5f))".Eval == "0");
  assert("(+ 1 2) (+ 5 1)".Eval == "6");
  // --- basic math (* / pow)
  assert("(* 2 2)".Eval == "4");
  assert("(* 2.5f 2.0f)".Eval == "5");
  assert("(/ 1000 2)".Eval == "500");
  assert("(/ 999  2)".Eval == "499.5");
  assert("(// 999  2)".Eval == "499.5");
  assert("(/ 999.0f 2.0f)".Eval.to!float == 499.5f);
  assert("(pow 5 3)".Eval == "125");
  // --- constants
  assert(Float_Cmp("(pow E PI)".Eval.to!float, 23.1406926328f, 0.001f));
  assert(Float_Cmp("(- (* 2 PI) TAU)".Eval.to!float, 0.0f, 0.1f));
  assert(Float_Cmp("(- (/ PI 4) PI-4)".Eval.to!float, 0.0f, 0.1f));
  // --- std.math functions
  assert(Float_Cmp("(sqrt 2.0f)".Eval.to!float, 1.414213f, 0.001));
  assert(Float_Cmp("(+ (sin PI) (cos PI))".Eval.to!float, -1.0f, 0.0001));
  assert(Float_Cmp("(atan (log LN2) (exp 20))".Eval.to!float, -0.351, 0.01));
  // --- lists
  assert("'(1 some-symbol 3 some-func 123123.0f)".Eval);
  assert("(car '(rose 1.3f asdf))".Eval == "rose");
  assert("(car (cdr '(rose 1.3f asdf)))".Eval == "1.3f");
  assert("(car (cons asdf [rose 1.3f]))".Eval == "asdf");
  assert("(car (car (cdr [a [b c d] e f])))".Eval == "b");
}
