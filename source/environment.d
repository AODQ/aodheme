module environment;
import atom, functions;

Environment global_environment;

alias FnType  = Function[string];
alias VarType = Atom[string];
class Environment {
public:
  VarType vars;
  Environment outer_env;

  this ( Atom[] parameters, Atom[] arguments, Environment outer_env_ ) {
    import std.range;
    foreach ( tup; zip(parameters, arguments) )
      vars[tup[0].To_String] = tup[1];
    import std.stdio;
    outer_env = outer_env_;
  }

  this ( ) {
    outer_env = null;
  }

  Atom Search ( Atom val ) {
    return Search ( val.To_String );
  }

  Atom Search ( string val ) {
    if ( val in vars ) return vars[val];
    assert(outer_env !is null, "Could not find: " ~ val);
    return outer_env.Search(val);
  }
}

auto Construct_Default_Environment ( )() {
  Environment t_env = new Environment();
  import std.math, std.conv, std.string, std.format, std.algorithm, std.range;

  t_env.vars = [
    "TAU":        Atom(std.math.PI*2       ),
	  "E":          Atom(std.math.E          ),
    "PI":         Atom(std.math.PI         ),
    "PI-2":       Atom(std.math.PI_2       ),
    "PI-4":       Atom(std.math.PI_4       ),
    "M-1-PI":     Atom(std.math.M_1_PI     ),
    "M-2-PI":     Atom(std.math.M_2_PI     ),
    "M-2-SQRTPI": Atom(std.math.M_2_SQRTPI ),
    "LN10":       Atom(std.math.LN10       ),
    "LN2":        Atom(std.math.LN2        ),
    "LOG2":       Atom(std.math.LOG2       ),
    "LOG2E":      Atom(std.math.LOG2E      ),
    "LOG2T":      Atom(std.math.LOG2T      ),
    "LOG10E":     Atom(std.math.LOG10E     ),
    "SQRT2":      Atom(std.math.SQRT2      ),
    "SQRT1-2":    Atom(std.math.SQRT1_2    ),
  ];

  string Arithmetic_Mix ( string mixer ) {
      // turns %s + %s to return Atom( cast_val(0) + cast_val(1) )
    string AMixHelper ( ) {
      string cast_val =
        `(args[%s].RType == typeid(int) ? args[%s].RInt : args[%s].RFloat)`;
      string cast_val_0 = cast_val.format("0", "0", "0"),
             cast_val_1 = cast_val.format("1", "1", "1");
      if ( mixer.count("%s") == 1 ) {
        return mixer.format(cast_val_0);
      } else if ( mixer.count("%s") == 2 ) {
        return mixer.format(cast_val_0, cast_val_1);
      }
      assert(false);
    }

    return `return Atom(` ~ AMixHelper() ~ `);`;
  }

  string FuncMixin ( string func, string operation = "") {
    // Gets a chunk (function name, operation code)
    // and formats it to setting the environment along with arithmetic mixin
    // so we can handle both ints and floats
    return q{
      t_env.vars["%s"] = Atom(new Fn((Atom[] args, Environment env) {
        mixin(Arithmetic_Mix(`%s`));
      }));
    }.format(func, operation);
  }

  string UltFuncMixin ( T... ) ( T arg ) {
    return [arg].chunks(2)
                .map!(n => FuncMixin(n[0], n[1]))
                .joiner.array.to!string;
  }

  alias Fn = Function;
  mixin(UltFuncMixin(
    "abs", `abs(%s)`, "acos", `acos(%s)`, "acosh", `acosh(%s)`,
    "approxEqual", `approxEqual(%s, %s)`, "asin", `asin(%s)`,
    "asinh", `asinh(%s)`, "atan2", `atan2(%s, %s)`, "atan", `atan(%s)`,
    "atanh", `atanh(%s)`, "cbrt", `cbrt(%s)`, "ceil", `ceil(%s)`,
    "cos", `cos(%s)`, "cosh", `cosh(%s)`, "exp2", `exp2(%s)`, "exp", `exp(%s)`,
    "expm1", `expm1(%s)`, "floor", `floor(%s)`, "fmax", `fmax(%s, %s)`,
    "fmin", `fmin(%s, %s)`, "fmod", `fmod(%s, %s)`,
    "hypotenuse", `hypot(%s, %s)`, "log10", `log10(%s)`, "log1p",`log1p(%s)`,
    "log2", `log2(%s)`, "logb", `logb(%s)`, "log", `log(%s)`,
    "nextDown", `nextDown(%s)`, "next", `nextPow2(%s)`, "nextUp", `nextUp(%s)`,
    "pow", `pow(%s, %s)`, "remainder", `remainder(%s, %s)`,
    "round", `round(%s)`, "sinh", `sinh(%s)`, "sin", `sin(%s)`,
    "sqrt", `sqrt(%s)`, "-", `%s - %s`, "/", `%s / %s`,
    "*", `%s * %s`, "+", `%s + %s`, "//", `(%s / %s).to!int`,
    "tanh", `tanh(%s)`, "tan", `tan(%s)`, "truncate", `trunc(%s)`
  ));

  void Add_Fn(string name, Atom delegate(Atom[], Environment) deleg) {
    t_env.vars[name] = Atom(new Fn(deleg));
  }

  Add_Fn("car", (Atom[] args, Environment env) {return args[0].RList[0];});
  Add_Fn("cdr", (Atom[] args, Environment env) {return Atom(args[0].RList[1..$]);});
  Add_Fn("cons", (Atom[] args, Environment env) {return Atom(args[0] ~ args[1].RList);});
  Add_Fn("set", (Atom[] args, Environment env) {
    env.vars[args[0].RString] = args[1];
    return args[0];
  });
  Add_Fn("setg", (Atom[] args, Environment env) {
    global_environment.vars[args[0].RString] = args[1];
    return Atom("");
  });
  Add_Fn("if", (Atom[] args, Environment env) {
    return args[0].To_String == "1" ? args[1] : args[2];
  });
  Add_Fn ("writeln", (Atom[] args, Environment env) {
    import std.stdio : writeln;
    writeln(args.map!(n => n.To_String));
    return Atom("");
  });
  Add_Fn ("==", (Atom[] args, Environment env) {return Atom(args[0].To_String == args[1].To_String);});
  Add_Fn ("<",  (Atom[] args, Environment env) {mixin (Arithmetic_Mix (q{%s < %s}));});
  Add_Fn (">",  (Atom[] args, Environment env) {mixin (Arithmetic_Mix (q{%s > %s}));});
  Add_Fn ("<=", (Atom[] args, Environment env) {mixin (Arithmetic_Mix (q{%s <= %s}));});
  Add_Fn (">=", (Atom[] args, Environment env) {mixin (Arithmetic_Mix (q{%s >= %s}));});
  return t_env;
}

Atom Func_Call ( Atom func, Atom[] args, Environment env ) {
  import std.math, std.stdio, std.conv : to;

  return func.RFunction.Call(env, args);
}
