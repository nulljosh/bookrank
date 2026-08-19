# Calculus For Dummies, 2nd Edition

# Chapters 1–9: Calculus For Dummies, 2nd Edition

## Chapter 1: What Is Calculus?
Calculus studies change and motion — it extends algebra/geometry/trig to curves and instantaneous rates, where those tools only handle straight lines and constant rates. Two central ideas: differentiation (finding slopes/rates of change) and integration (finding areas/accumulated totals). Real-world examples: a football's optimal throwing angle, calculating orbital paths of planets, engineering problems involving changing quantities.

## Chapter 2: The Two Big Ideas of Calculus
- **Differentiation**: the derivative of a function is both a slope (geometric) and a rate (physical) — e.g. velocity is the derivative of position.
- **Integration**: the "backwards" operation — finding the area under a curve by (conceptually) adding up infinitely many infinitely thin rectangles.
- **Infinite series**: sums of infinitely many terms. Illustrated with Zeno's paradox (Achilles and the tortoise) — despite the tortoise having a head start, the infinite series of ever-shrinking time gaps Achilles needs to catch up sums to a *finite* total time (worked example: Achilles passes the tortoise after 11⅑ seconds), resolving the apparent paradox.
  - **Convergent series**: sum approaches a finite total as more terms are added.
  - **Divergent series**: sum grows without bound.

## Chapter 3: Why Calculus Works
Calculus works because if you zoom in far enough on any smooth curve, it looks straight — "locally straight." This is the core insight: the **limit** concept is a mathematical microscope that lets you zoom in on a curve infinitely, until it behaves like a straight line, letting you use ordinary algebra/geometry (slope, area of triangle = ½ base × height, Pythagorean theorem a² + b² = c²) on curves. Two caveats given: (1) this zooming-in is a rigorous limit process, not literal infinite zooming, and (2) "infinity" isn't a number you can do arithmetic with — it's a process/concept describing unboundedness.

## Chapter 4: Pre-Algebra and Algebra Review
Refresher on algebra needed for calculus:
- **Fractions**: multiplying (multiply straight across), dividing (multiply by reciprocal), adding/subtracting (common denominator), canceling (only valid across multiplication, never across addition/subtraction terms).
- **Powers and roots**: rules for exponents (product, quotient, power-of-power), negative exponents (reciprocal), fractional exponents (roots), and root simplification rules.
- **Logarithms**: introduced as the inverse of exponentiation ("a lumberjack competition" mnemonic framing); log properties (log of product = sum of logs, log of power = exponent × log).
- **Factoring**: GCF (greatest common factor) pulling, difference of squares, sum/difference of cubes, trinomial factoring.
- **Solving quadratic equations**, three methods:
  1. **Factoring** — write as product of two binomials, set each factor to zero.
  2. **Quadratic formula** — x = (−b ± √(b²−4ac))/2a; discriminant (b²−4ac) tells you whether roots are real/rational.
  3. **Completing the square** — isolate x-terms, divide by leading coefficient, add (half the x-coefficient)² to both sides, factor as a perfect-square binomial, take the square root of both sides (± sign).

## Chapter 5: Funky Functions and Their Groovy Graphs
- A **function** has exactly one output for each input (the defining characteristic) — visualized as a machine with input/output.
- **Independent vs. dependent variables**: input (x) is independent, output (y = f(x)) is dependent.
- **Function notation** f(x), and **composite functions** f(g(x)) — evaluate the inner function first, then plug that result into the outer function.
- **Vertical line test**: if a vertical line crosses a graph more than once, it's not a function.
- Common function families and their graphs: lines, parabolas, absolute value (V-shaped, even), exponential functions (aˣ), logarithmic functions (inverse of exponential), and general polynomial curve shapes.
- **Inverse functions**: f⁻¹(x) undoes f(x); graphically, a function and its inverse are mirror images across the line y = x. Only functions that are one-to-one (pass a horizontal line test) have true inverses.
- **Transformations**: shifting a function up/down/left/right, reflecting, stretching/shrinking — achieved by adding/subtracting/multiplying constants inside or outside f(x).
  - Vertical transformations: f(x) + k shifts up/down; k·f(x) stretches/shrinks vertically; −f(x) reflects over the x-axis.
  - Horizontal transformations: f(x + k) shifts left/right (opposite sign intuition); f(kx) stretches/shrinks horizontally; f(−x) reflects over the y-axis.

## Chapter 6: The Trig Tango
- SOH-CAH-TOA basics: sine = opposite/hypotenuse, cosine = adjacent/hypotenuse, tangent = opposite/adjacent, plus reciprocal functions (cosecant, secant, cotangent).
- **Two special right triangles**: 45°-45°-90° (legs equal, hypotenuse = leg × √2) and 30°-60°-90° (sides in ratio 1 : √3 : 2) — used to derive exact trig values for 30°, 45°, 60°.
- **The unit circle**: radius-1 circle centered at origin; any point on it is (cos θ, sin θ) for angle θ measured from the positive x-axis. Radians defined (360° = 2π radians); memorizing coordinates at standard angles (0°, 30°, 45°, 60°, 90°, etc. and their reflections in all four quadrants).
- **Graphing sine, cosine, tangent**: periodic wave shapes, amplitude, period, and how the unit circle values map onto the wave graphs.
- **Inverse trig functions** (arcsin, arccos, arctan): restricted domains/ranges needed so they qualify as true functions (since regular trig functions aren't one-to-one over their full domain).
- **Trig identities**: Pythagorean identity sin²x + cos²x = 1, double angle formula sin 2x = 2 sin x cos x, and a pointer to the book's online Cheat Sheet for more.

## Chapter 7: Limits and Continuity
- **Informal definition of a limit**: the value a function *approaches* as x approaches some number, whether or not the function actually reaches (or is even defined at) that value.
- Illustrated with a table of input/output values getting closer and closer to a target x, showing the output converging to a limit value.
- **One-sided limits**: the limit as you approach from the left vs. right — must be equal for the two-sided limit to exist.
- **Limits and vertical asymptotes**: a function has a vertical asymptote where limits go to ±infinity as x approaches a value from one/both sides.
- **Limits and horizontal asymptotes**: limits as x → ±infinity describe the function's long-run flat-line behavior.
- **Instantaneous speed via limits**: motivating example computing average speed over shrinking time intervals, with the limit as the interval shrinks to zero giving the instantaneous speed — foreshadowing the derivative.
- **Formal (epsilon-style) definition of a limit**: the limit L exists at x = c if, for any tiny required closeness to L, you can find a small enough window around c (excluding c itself) that guarantees the function stays within that closeness — described via the classic "for all ε, there exists δ" framework, informally.
- **Continuity**: a function is continuous at a point if the limit exists there, the function is defined there, and the limit equals the function value. Polynomial and rational functions are continuous everywhere they're defined.
- **The "hole" exception**: a function can have a removable discontinuity (a hole) where the limit exists but doesn't equal the function value (or the function isn't defined there) — the rest of the function can still behave continuously around the hole.
- **The 3-3-3-3 Limit Mnemonic**: summarizes 3 conditions for continuity at a point, 3 types of discontinuity (jump, infinite, removable/hole), 3 cases where a limit fails to exist, and 3 cases where a derivative fails to exist (discontinuity, sharp corner/cusp, vertical tangent).

## Chapter 8: Evaluating Limits
Techniques for computing limits:
- **Limits to memorize**: lim c = c (constant), and other basic limit facts.
- **Plugging and chugging**: direct substitution when the function is continuous at that point.
- **Calculator methods**: using a table of values or graphing to approximate a limit numerically (e.g. TI-84 table-building), while noting calculators can mislead near tricky points.
- **Factoring algebra tricks**: canceling common factors from numerator/denominator (removes a hole) before substituting.
- **Conjugate multiplication**: for limits involving square roots, multiply numerator and denominator by the conjugate to eliminate the radical, then simplify and substitute — worked example: lim(√(x²+x) − x) as x→∞ evaluated by multiplying by the conjugate over itself, simplifying, and substituting to get ½.
- **The "sandwich" (squeeze) theorem**: if a tricky function is squeezed between two other functions that both converge to the same limit at a point, the tricky function has that same limit too.
- **Limits at infinity**: evaluating end behavior of rational functions by comparing degrees of numerator/denominator — degree of denominator higher → limit is 0; equal degrees → limit is ratio of leading coefficients; numerator degree higher → limit is ±infinity.

## Chapter 9: Differentiation Orientation
Introduces the derivative conceptually before the formal rules (covered in Ch. 10):
- The derivative is fundamentally about finding the **slope** of a curve at a single point — extending "slope" beyond straight lines.
- **Average rate vs. instantaneous rate**: average rate = slope of a secant line between two points (Δy/Δx); instantaneous rate = slope of the tangent line at a single point, found by taking the limit of the secant slope as the second point moves infinitely close to the first (the difference quotient: lim_{h→0} [f(x+h) − f(x)]/h).
- Worked examples showing secant lines getting closer and closer to the tangent line as the second point approaches the point of tangency, with slopes numerically converging (e.g. secant slopes of 6.4, 6.2, 6.04... converging toward a tangent slope of 6 at the point (2,4) on y = x²).
- **Formal definition of the derivative**: f'(x) = lim_{h→0} [f(x+h) − f(x)]/h — the derivative as a function in its own right, giving the slope at every x where it's defined.
- **Speed as the most familiar rate**: derivative of position with respect to time = velocity; illustrated with a playground/swing example computing instantaneous speed from a position function.
- **Three cases where a derivative fails to exist**: (1) any type of discontinuity, (2) a sharp point/corner or cusp on the function, (3) a vertical tangent line (undefined slope).

## Key Takeaways
- Calculus formalizes "zooming in" on curves until they look straight, via limits — this is the foundation for both differentiation and integration.
- Chapters 4–6 are algebra/trig review — essential prerequisite fluency, not new calculus content.
- Chapter 7–8 build the limit toolbox (memorized limits, algebra tricks, squeeze theorem, infinity behavior) that underlies every derivative calculation.
- Chapter 9 defines the derivative as the limit of the difference quotient — the slope of the tangent line — setting up the shortcut differentiation rules in Chapter 10.

---

# Chapter 10: Differentiation Rules — Yeah, Man, It Rules

## Overview
Builds shortcut rules for finding derivatives so you can avoid grinding through limits and the difference quotient every time. The formal limit definition of the derivative (from Chapter 9) still underlies these rules, but in practice you'll use these shortcuts.

## The Constant Rule
If f(x) = c (a constant), then f'(x) = 0. The derivative of any constant is zero — makes sense since a horizontal line has zero slope everywhere.

## The Power Rule
For f(x) = xⁿ, f'(x) = nxⁿ⁻¹: bring the exponent down in front as a coefficient, then subtract 1 from the exponent.
- Applies to negative and fractional exponents too (e.g. rewrite 1/x² as x⁻² before differentiating, and √x as x^(1/2)).

## The Constant Multiple Rule
If g(x) = c·f(x), then g'(x) = c·f'(x) — a constant multiplier just carries through the derivative unchanged.

## Sum and Difference Rules
- **Sum rule**: derivative of a sum of terms = sum of the derivatives of each term (differentiate term by term).
- **Difference rule**: same idea for subtraction — differentiate each term separately, keep the sign.

## Differentiating Trig Functions
Standard derivatives to memorize:
- d/dx(sin x) = cos x
- d/dx(cos x) = −sin x
- d/dx(tan x) = sec²x
- d/dx(cot x) = −csc²x
- d/dx(sec x) = sec x tan x
- d/dx(csc x) = −csc x cot x

## Differentiating Exponential and Logarithmic Functions
- d/dx(eˣ) = eˣ — the special property that makes e the natural base for calculus (its derivative is itself).
- d/dx(aˣ) = aˣ · ln a for other bases a.
- d/dx(ln x) = 1/x
- d/dx(logₐ x) = 1/(x ln a)

Photo: a graph showing y = e^x-like exponential decay/growth curve with slope annotations at a point, illustrating that the tangent slope equals the function value at that point.

## The Product Rule
For y = f(x)·g(x): y' = f'·g + f·g' — "first times derivative of second, plus second times derivative of first."

## The Quotient Rule
For y = f(x)/g(x): y' = (f'g − fg')/g² — remembered via a mnemonic rhyme ("low d-high minus high d-low, over the square of what's below").

## The Chain Rule
For composite functions y = f(g(x)): y' = f'(g(x)) · g'(x) — differentiate the "outside" function first (leaving the inside alone), then multiply by the derivative of the "inside" function.
- Steps given for handling nested/composite functions: identify the outside function, differentiate it while temporarily replacing the inside with a placeholder, then multiply by the derivative of the inside.
- For functions with multiple layers of nesting (composite of a composite), the chain rule is applied repeatedly, working from the outermost layer in.
- A sidebar ("Why the Chain Rule Works") gives an informal derivation showing the chain rule follows from writing the derivative as a limit of ratios and multiplying by a strategically chosen fraction equal to 1 (Δu/Δu), splitting Δy/Δx into (Δy/Δu)·(Δu/Δx).

## Differentiating Implicitly
For equations where y isn't isolated (e.g. x²y³ + something = something), implicit differentiation:
1. Differentiate each term on both sides with respect to x, treating y as a function of x (so any term with y needs the chain rule, producing a dy/dx factor).
2. Collect all terms containing dy/dx on one side of the equation.
3. Factor out dy/dx.
4. Divide to solve for dy/dx.

## Logarithmic Differentiation
For functions where the variable appears in both the base and exponent, or products/quotients of many factors: take the natural log of both sides first, use log properties (log of a product → sum of logs, log of a power → exponent times log) to simplify, then differentiate implicitly and solve for dy/dx. Useful because logs turn hard-to-differentiate products/quotients/powers into easy-to-differentiate sums.

## Differentiating Inverse Functions
If f and g are inverse functions, then g'(x) = 1/f'(g(x)) — the derivative of the inverse at a point is the reciprocal of the derivative of the original function at the corresponding point. Illustrated with a graph showing a function and its inverse as mirror images across y = x, with reciprocal slopes at corresponding points.

## Scaling the Heights of Higher-Order Derivatives
The derivative of a derivative is the **second derivative** (f''), and the process repeats indefinitely for third, fourth, etc. derivatives — each higher derivative measures the rate of change of the one before it (e.g. velocity → acceleration → jerk). Polynomial functions eventually reach a derivative of zero after enough repetitions, since each differentiation drops the degree by one.

## Key Takeaways
- Memorize the constant, power, sum/difference, product, quotient, and chain rules — they cover the vast majority of derivatives you'll need.
- The chain rule is essential for any composite function and often combines with the product/quotient rules.
- Implicit and logarithmic differentiation extend these rules to equations that aren't explicitly solved for y, or that are awkward to differentiate directly.
- Higher-order derivatives are just repeated applications of the same rules.

---

# Chapters 11–14: Calculus For Dummies, 2nd Edition

## Chapter 11: Differentiation and the Shape of Curves
Uses derivatives to understand a function's overall shape.
- **Extrema (local max/min)**: found at **critical numbers** — points where f'(x) = 0 or is undefined.
- **The first derivative test**: at a critical number, if f' switches from positive to negative, it's a local max; negative to positive, a local min; no sign change, neither.
- **The second derivative test**: alternative test — if f''(c) > 0 at a critical point, it's a local min (concave up, "smiling"); if f''(c) < 0, it's a local max (concave down, "frowning"); if f''(c) = 0, the test is inconclusive and you fall back to the first derivative test.
- **Absolute extrema on a closed interval**: check the function's value at all critical numbers inside the interval AND at both endpoints — the largest/smallest of these is the absolute max/min.
- **Absolute extrema over a function's entire domain**: also check the function's behavior as x → ±infinity (or toward domain boundaries/vertical asymptotes) in addition to critical numbers.
- **Concavity and inflection points**: found using the **second derivative**. f'' > 0 → concave up; f'' < 0 → concave down. An inflection point is where concavity switches sign (f'' = 0 or undefined, and the sign actually changes on either side).
- **Reading graphs of derivatives**: given the graph of f', you can infer where f is increasing/decreasing (sign of f'), and given the graph of f'', where f is concave up/down — practiced with several graph-matching exercises.
- **The Mean Value Theorem (MVT)**: if f is continuous on [a,b] and differentiable on (a,b), there exists at least one point c in (a,b) where the instantaneous rate of change equals the average rate of change over the interval: f'(c) = (f(b) − f(a))/(b − a). Geometrically, the tangent line at c is parallel to the secant line connecting the endpoints.

## Chapter 12: Your Problems Are Solved — Differentiation to the Rescue
Real-world applications of differentiation:
- **Optimization problems**: find the maximum or minimum value of a real-world quantity (e.g. maximum volume of a box built from a fixed-size sheet by cutting corner squares, maximum area of a corral given fixed fencing) by writing a formula for the quantity in terms of one variable, differentiating, setting equal to zero, and checking critical numbers (plus checking domain endpoints).
- **Position, velocity, and acceleration**: velocity is the derivative of position; acceleration is the derivative of velocity (second derivative of position). Worked "yo-yo" example computing max height (where velocity = 0) and analyzing sign of velocity/acceleration for motion direction and speeding up/slowing down.
- **Velocity, speed, and displacement vs. distance traveled**: velocity can be negative (direction matters), speed is always the absolute value of velocity. Total displacement is net change in position (can involve cancellation); total distance traveled sums the absolute values of each segment of motion (never cancels) — worked example computing both for a particle changing direction, with careful sign tracking between direction changes.
- **Related rates**: problems where multiple changing quantities are linked by an equation (e.g. volume of a sphere, similar-triangle geometry problems), and you differentiate the whole equation implicitly with respect to time to relate their rates of change. Worked examples: inflating balloon (rate of radius change given rate of volume change), filling a conical/triangular trough with water, and a two-car "distance between them" problem using the Pythagorean theorem plus implicit differentiation with respect to time. Steps given: draw a diagram, write an equation relating the variables, differentiate with respect to time, plug in known values, solve for the unknown rate.

## Chapter 13: More Differentiation Problems — Going Off on a Tangent
- **Tangent and normal lines**: the tangent line touches a curve at one point with slope equal to f'(x) there; the normal line is perpendicular to the tangent at that same point (slope = −1/f'(x)). Worked example finding tangent/normal line equations to a parabola at a given point using point-slope form.
- **Linear approximation**: near a point where a function is hard to compute exactly, approximate f(x) using the tangent line at a nearby easy point: f(x) ≈ f(a) + f'(a)(x − a). Useful for estimating values like square roots without a calculator, with the approximation getting less accurate the farther x is from a.
- **Business and economics applications**: marginal cost, marginal revenue, and marginal profit are the *derivatives* of the cost, revenue, and profit functions respectively — they approximate the cost/revenue/profit of producing one more unit. Maximum profit occurs where marginal profit = 0, i.e. where marginal cost equals marginal revenue.

## Chapter 14: Intro to Integration and Approximating Area
Begins Part 5, covering integration (the "reverse" of differentiation) — introduces area-under-a-curve problems and various approximation techniques before the exact integral is introduced in Chapter 15.
- **Integration as fancy addition**: the area under a curve can be approximated by summing many thin rectangles (or other shapes) and gets more exact as the number of pieces increases toward infinity — connecting integration conceptually to summation.
- **Approximating area with left sums**: build rectangles whose height is set by the function's value at the *left* edge of each subinterval; systematically undercounts area for an increasing function (overcounts for decreasing).
- **Approximating area with right sums**: rectangles use the function's value at the *right* edge of each subinterval; opposite bias — overcounts for an increasing function.
- **Approximating area with midpoint sums**: rectangles use the function's value at the *midpoint* of each subinterval — generally the most accurate simple Riemann sum method, since over/under errors tend to cancel.
- **Sigma (summation) notation**: Σ notation used to write these sums compactly, e.g. Rₙ = Σᵢ f(xᵢ)·Δx for right sums; introduces reading/writing sums with sigma notation.
- **Finding exact area with the definite integral**: taking the *limit* of these Riemann sums as the number of rectangles → infinity (and rectangle width → 0) gives the exact area — this limit is defined as the **definite integral** ∫ₐᵇ f(x) dx.
- **The trapezoid rule**: approximates area using trapezoids instead of rectangles (connecting function values at each subinterval's endpoints with a straight line on top) — generally more accurate than left/right/midpoint rectangle sums for the same number of subintervals.
- **Simpson's rule**: an even more accurate approximation method using parabolic arcs (rather than straight lines) to fit the curve over pairs of subintervals, giving very high accuracy with relatively few subintervals; formula involves alternating weighted coefficients (1, 4, 2, 4, 2, ..., 4, 1) on the function values at each partition point.

## Key Takeaways
- Chapter 11's first/second derivative tests and concavity analysis are how you go from "here's a derivative formula" to "here's what the function's graph actually looks like."
- Chapters 12–13 are the practical payoff of differentiation: optimization, motion problems, related rates, tangent-line approximation, and marginal analysis in economics — all just applications of the same core derivative rules from Chapter 10.
- Chapter 14 sets up integration as the limit of increasingly fine Riemann sums (left, right, midpoint, trapezoid, Simpson's) — the definite integral is defined as that limiting exact area, with Chapter 15 presumably covering how to compute it algebraically via antiderivatives.

---

# Chapters 15–22: Calculus For Dummies, 2nd Edition

## Chapter 15: Integration — It's Backwards Differentiation
- **Antidifferentiation**: the reverse of differentiation — if the derivative of x³ is 3x², the antiderivative of 3x² is x³ (plus an arbitrary constant, since constants vanish under differentiation).
- **The indefinite integral**: written ∫f(x)dx, represents the entire family of antiderivatives of f(x), differing only by a constant C — "+C" always required.
- **The area function** A(x): a function that sweeps out and measures the running area under a curve from a fixed start point up to x; introduced conceptually via a "swept rectangle" thought experiment.
- **The Fundamental Theorem of Calculus (Part 1)**: the derivative of the area function equals the original function: d/dx[A(x)] = f(x). This is the deep connection between differentiation and integration — area accumulation and rate of change are inverse processes.
- **The Fundamental Theorem of Calculus (Part 2)**: gives the shortcut for computing exact definite integrals without Riemann sums: ∫ₐᵇf(x)dx = F(b) − F(a), where F is any antiderivative of f. Demonstrated by computing area under a parabola exactly and confirming it matches the Chapter 14 Riemann-sum approximation.
- **Basic antiderivative rules** (reverse power rule, reverse rules for trig/exponential functions) given in a reference table — same functions as Chapter 10's differentiation rules, run in reverse.
- **Why the theorem works**: explained via the "area between two close x-values" argument — connects back to the definition of the derivative as a limit of a difference quotient, now applied to the area function.

## Chapter 16: Integration Techniques for Experts
Four advanced integration techniques beyond the basic reverse rules:
- **Guess-and-check**: guess an antiderivative form, differentiate to check, and adjust — a stepping stone to formal substitution.
- **The substitution method** (u-substitution): for composite functions, set u equal to the "inner" function, compute du, rewrite the integral entirely in terms of u, integrate, then substitute back. Effectively the integration version of the chain rule in reverse. Includes handling definite integrals by changing the limits of integration to match the new u-variable (avoids substituting back).
- **Integration by parts**: the integration version of the product rule. Formula: ∫u dv = uv − ∫v du. The **LIATE mnemonic** (Logarithmic, Inverse trig, Algebraic, Trigonometric, Exponential) helps decide which factor to call u (pick the type highest on this list first). Sometimes requires applying integration by parts twice ("second time as the first") to fully resolve an integral.
- **Trigonometric integrals**: techniques for integrating powers/products of sine and cosine using the Pythagorean identity (sin²x + cos²x = 1) to convert one function's power so a u-substitution becomes available — cases split by whether the power of sine is odd, whether the power of cosine is odd, or whether both powers are even (using half-angle identities in the even-even case). Similar case-based techniques for integrals of secant/tangent and cosecant/cotangent products.
- **Trigonometric substitution**: for integrals containing expressions like √(a²−x²), √(a²+x²), or √(x²−a²), substitute x with a trig function (e.g. x = a sin θ) using a reference right triangle to convert the radical into a simplifiable trig expression, then convert back at the end.
- **Partial fractions**: for integrating rational functions (polynomial over polynomial) where the denominator factors — break the fraction into a sum of simpler fractions with unknown constants (A, B, C...) in the numerators over each factor. Two cases: denominator has only linear factors (solve for constants by plugging in roots), or denominator has an irreducible quadratic factor (solve via equating coefficients of like terms, a system of equations).

## Chapter 17: Forget Dr. Phil — Use the Integral to Solve Problems
Real-world/geometric applications of the definite integral:
- **Mean Value Theorem for Integrals**: guarantees a point c in [a,b] where f(c) equals the *average value* of the function over the interval — average value = (1/(b−a))∫ₐᵇf(x)dx. The rectangle with that height and width (b−a) has the same area as the region under the curve.
- **Area between two curves**: ∫[top function − bottom function]dx over the interval where they don't cross; if curves cross, split the integral at intersection points and treat each sub-region separately (may need to swap which function is "top" for each piece).
- **Finding volumes of solids ("weird shapes")** via the **meat-slicer method**: slice the solid into thin cross-sections, find the area of a representative cross-sectional slice as a function of position, then integrate that area function over the solid's extent to get total volume — ∫A(x)dx.
- **The disk method**: for a solid of revolution (formed by rotating a curve around an axis), each cross-sectional slice is a circular disk; volume = π∫[radius(x)]²dx.
- **The washer method**: like the disk method but for solids with a hole down the middle (e.g. rotating the region between two curves) — each slice is a washer (disk with a smaller disk subtracted); volume = π∫([outer radius]² − [inner radius]²)dx.
- **The "matryoshka-doll" (cylindrical shell) method**: an alternative to disk/washer for certain solids of revolution — imagines the solid as nested cylindrical shells rather than stacked disks; volume = 2π∫[radius × height]dx. Useful when the axis of rotation makes the disk/washer method awkward.
- **Arc length**: the length of a curve from x=a to x=b is found by integrating √(1 + (dy/dx)²)dx — derived from approximating the curve with tiny straight-line (hypotenuse) segments and applying the Pythagorean theorem, then taking the limit as the segments shrink.
- **Surface area of revolution**: formula for the surface area generated by revolving a curve around an axis, built from thin circular "bands" (like a bottle's surface) — Surface Area = 2π∫r(x)√(1 + (dy/dx)²)dx, where r(x) is the distance from the curve to the axis of rotation.

## Chapter 18: Taming the Infinite with Improper Integrals
- **Improper integrals**: integrals where either a limit of integration is infinite, or the integrand has a vertical asymptote within (or at an endpoint of) the interval — can't evaluate with the ordinary Fundamental Theorem directly.
- **L'Hôpital's Rule**: shortcut for evaluating limits that come out to indeterminate forms (0/0 or ∞/∞) — take the derivative of the numerator and denominator separately (not the quotient rule) and retry the limit; can be applied repeatedly if still indeterminate. Also covers converting other indeterminate forms (∞−∞, 0·∞, 1^∞, etc.) into 0/0 or ∞/∞ form first via algebra/logs so L'Hôpital's applies.
- **Improper integrals with an infinite limit of integration**: rewrite as a limit, e.g. ∫ₐ^∞f(x)dx = lim_{b→∞}∫ₐᵇf(x)dx; the integral "converges" if this limit exists (is finite), "diverges" otherwise.
- **Improper integrals with a vertical asymptote**: split the integral at the asymptote if it's in the interior, and rewrite each piece as a one-sided limit approaching the asymptote from the appropriate side.
- **Improper integrals with two infinite/problematic bounds**: split into two separate improper integrals (each handled independently) — the whole integral only converges if both halves converge.
- **Gabriel's Horn**: the classic paradox example — a solid of revolution with finite volume but infinite surface area, illustrated by revolving y = 1/x around the x-axis from 1 to infinity. Demonstrates that convergence of volume and surface-area integrals aren't linked.

## Chapter 19: Infinite Series
Covers sequences, series, and ten tests for determining convergence/divergence.
- **Sequences**: ordered lists of numbers following a rule (aₙ); can be thought of as a function evaluated only at integers.
- **Series**: the sum of a sequence's terms (Σaₙ); **convergent** if the sum approaches a finite value, **divergent** otherwise.
- **Partial sums**: Sₙ, the sum of the first n terms — a series converges if and only if its sequence of partial sums converges to a finite limit.
- **The nth term test for divergence**: if lim_{n→∞} aₙ ≠ 0, the series definitely diverges (quick screening test — does NOT prove convergence if the limit is 0).
- **Three named series** (benchmarks used by comparison tests): 
  - **Geometric series** Σarⁿ — converges if |r| < 1 (to a/(1−r)), diverges otherwise.
  - **P-series** Σ1/nᵖ — converges if p > 1, diverges if p ≤ 1 (harmonic series is the p=1 case, famously divergent despite terms shrinking to 0).
  - **Telescoping series** — successive terms cancel out algebraically, leaving only a few surviving terms so the sum can be computed directly.
- **Three comparison tests** (compare an unknown series to a known benchmark series): direct comparison test, limit comparison test, integral comparison test (only for positive, decreasing, continuous terms — compares the series to ∫f(x)dx).
- **Two "R" tests** (self-contained, don't need a benchmark): the **ratio test** and the **root test** — both take a limit involving the nth and (n+1)th terms (ratio test) or nth root of the nth term (root test); limit < 1 → converges, > 1 → diverges, = 1 → inconclusive.
- **Alternating series**: terms alternate sign; the **alternating series test** checks that terms shrink monotonically to 0 for convergence.
- **Absolute vs. conditional convergence**: a series converges *absolutely* if the series of absolute values also converges (stronger); it converges *conditionally* if it converges only with the alternating signs, not with all-positive terms.
- Chapter closes with a summary "cheat sheet" grouping all ten tests into three families (named-series benchmarks, comparison tests, and the paired nth-term/alternating tests).

## Chapters 20–22: The Part of Tens
- **Chapter 20 — Ten Things to Remember**: quick-reference formulas worth memorizing cold — SOH-CAH-TOA, exact trig values at 30°/45°/60°, sin²θ + cos²θ = 1, the product rule, the quotient rule, and the fact that 5/0 is undefined while 0/5 = 0.
- **Chapter 21 — Ten Things to Forget**: common wrong "shortcuts" students mistakenly apply — (a+b)² ≠ a² + b², √(a²+b²) ≠ a+b, slope is NOT (x₂−x₁)/(y₂−y₁) (it's flipped), 3a+b ≠ 3a+2 nonsense misreadings, treating a variable like a constant when differentiating, misapplying the quotient rule, forgetting +C, and misstating Green's Theorem.
- **Chapter 22 — Ten Things You Can't Get Away With**: humorous list of exam-cheating tactics that don't work — giving two conflicting answers, illegible handwriting, not showing work, blaming a study partner, claiming morning exams are unfair, pulling a fire alarm, using the book as an excuse, etc.

## Key Takeaways
- Chapter 15's Fundamental Theorem of Calculus is the capstone connecting differentiation and integration — it's why definite integrals can be computed via antiderivatives instead of Riemann sums.
- Chapter 16 supplies the integration technique toolkit (substitution, by parts, trig integrals/substitution, partial fractions) needed for most non-trivial integrals.
- Chapter 17 is the practical payoff of integration: areas between curves, volumes of solids (disk/washer/shell), arc length, and surface area.
- Chapter 18's L'Hôpital's Rule and improper integral techniques handle the "edge cases" — infinite bounds and discontinuities.
- Chapter 19 rounds out the book with infinite series and the ten convergence/divergence tests, the third major topic alongside differentiation and integration.
