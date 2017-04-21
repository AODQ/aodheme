module aodheme;
public import interpreter : Initialize, Evaluate;
import std.stdio;

unittest {
  import std.conv;
  import interpreter;
  float Float_Cmp ( float a, float b, float c ) {
    import std.math : abs;
    return abs(a - b) < c;
  }
  // --- integer/flots
  assert("(+ 1 2)".Eval == "3");
  assert("(+ 1.5f 2.0f)".Eval == "3.5");
  // --- parenthesis/s-exprs
  assert("(+ (+ 1 2) -3)".Eval == "0");
  assert("(+ (+ 1 2) (+ 1 2))".Eval == "6");
  assert("(- (+ (+ 0.5f (- 0.5f 0.5f)) 0.5f) (+ 0.5f 0.5f))".Eval == "0");
  assert("(+ 1 2) (+ 5 1)".Eval == "6");
  assert("((+ ((1)) (((2)))))".Eval == "3");
  // --- basic math (* / pow)
  assert("(* 2 2)".Eval == "4");
  assert("(* 2.5f 2.0f)".Eval == "5");
  assert("(/ 1000 2)".Eval == "500");
  assert("(/ 999  2)".Eval == "499.5");
  assert("(// 999  2)".Eval == "499");
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
  assert("~(1 some-symbol 3 some-func 123123.0f)".Eval);
  assert("(car ~(rose 1.3f asdf))".Eval == "rose");
  assert("(car (cdr ~(rose 1.3f asdf)))".Eval == "1.3f");
  assert("(car (cons ~asdf [rose 1.3f]))".Eval == "asdf");
  assert("(car (car (cdr [a [b c d] e f])))".Eval == "b");
  // --- custom variables
  assert("(set ~A-Thing 20) (+ A-Thing 40)".Eval == "60");
  assert(q{
    (set ~A 10)
    (set ~B 10)
    (set ~C 10)
    (set ~D (+ (pow 2 2) 6))
    (- (+ A B) (+ C D))
  }.Eval == "0");
  // --- custom functions
  assert(q{
    (set ~A (lambda (x y) {
      ((+ x y) (- x y))
    }))
    (A -1 1)
  }.Eval == "0");
  assert(q{
    (if (> 2.0f 5.0f)
        ~asdf
        (((+ 5 5))))
  }.Eval == "10");
  assert(q{
    (set ~A (lambda (x) {(+ x x)}))
    (+ 10 50)
    (set ~B (lambda (x) {(+ x x)}))
    (A (B 5))
    (A (A (B (A (B 5) 5) 5) 5) 5)
    }.Eval == "160");
  assert(q{
    (set ~B (lambda (x) {((pow x x))}))
    (B 2)
  }.Eval == "4");
  assert(q{
    (set ~A (lambda (x) {
      (set ~B (lambda (x) {
        (set ~C (lambda (x y) {
          (+ 10 10)
          (pow x y)
        }))
        (* 2 50)
        (C (+ 10 x) (- 10 x))
      }))
      (B (+ x 3))
    }))
    (A 2)
  }.Eval == "759375");
  assert(q{
    ((lambda (x y z) {
      (* (* x y) z)
    }) 10 10 10)
  }.Eval == "1000");
  foreach ( i; 0 .. 50 ) writeln("\n\n");
  q{
    (set ~length (lambda (array) {
      (set ~lhelp (lambda (array t) {
        (writeln (empty array))
        (if (empty array)
          (t)
          (lhelp (cdr array) (+ t (car array))))
      }))
      (lhelp array 0.0f)
    }))
    (set ~sdSphere (lambda (point radius) {
      (- (length point) radius)
    }))
    (set ~Map (lambda (point) {
      (sdSphere (point 4.0f))
    }))
  }.Eval.writeln;
}
