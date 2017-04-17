module functions;
import atom, environment, pegged.grammar : ParseTree;

private alias FnDType = Atom delegate(Atom[], Environment);
private enum FunctionBaseType { parse_tree, deleg };

private union FunctionBase {
  ParseTree parsetree;
  FnDType deleg;
}

class Function {
  Atom[] parameters;
  FunctionBase func;
  FunctionBaseType func_type;
  Environment env;

  this ( Atom[] parameters_, ParseTree func_ ) {
    parameters     = parameters_.dup;
    import std.stdio;
    func.parsetree = func_;
    func_type      = FunctionBaseType.parse_tree;
  }

  this ( FnDType func_ ) {
    func.deleg = func_;
    func_type  = FunctionBaseType.deleg;
  }

  Atom Call ( Environment base_env, Atom[] args ) {
    if ( func_type == FunctionBaseType.parse_tree ) {
      env = new Environment(parameters, args, base_env);
      import interpreter;
      import std.stdio;
      return Eval_Tree ( func.parsetree, env );
    } else {
      return func.deleg(args, base_env);
    }
  }
}
