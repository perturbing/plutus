-- chooseList should accept arbitrary terms in the branches
(program 1.0.0 [[[(force (force (builtin chooseList))) (con (list integer) [ 0, 1, 2 ])] (lam x x)] (lam y (lam z z))])