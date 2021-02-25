% opdraw.mp
% Copyright (c) 2021 J. M. Spivey

numeric gridx, gridy; gridx = 72pt; gridy = 36pt;
numeric odx, ody; odx = 6pt; ody = 12pt;
numeric linkw; linkw = 20pt;
numeric linkd; linkd = 1.2pt;
numeric regdot; regdot = 4pt;
numeric outline; outline = 0.4pt;

vardef pale(expr c) = 0.2[white, c] enddef;

vardef width primary p = xpart (urcorner p - llcorner p) enddef;

color pastel[];
pastel0 = pale((1, 0, 0));
pastel1 = pale((1, 2/3, 0));
pastel2 = pale((1, 1, 0));
pastel3 = pale((0, 1, 0));
pastel4 = pale((0, 1, 1));
pastel5 = pale((0, 0, 1));
pastel6 = pale((1, 0, 1));

def shade(expr n) expr p =
  fill p withcolor pastel[n mod 7];
  draw p
enddef;

vardef node@#(expr x, y, p) =
  z.a@# = (x*gridx, y*gridy);
  z.a@#t-z.a@# = z.a@#-z.a@#b = (0,ody);
  z.a@#r-z.a@# = z.a@#-z.a@#l = (1/2 width p + odx,0);
  z.a@#tr = (xpart z.a@#r, ypart z.a@#t);
  z.a@#tl = (xpart z.a@#l, ypart z.a@#t);
  pic@# = p shifted (z.a@# - center p);
enddef;

vardef link@#(suffix $, $$) =
  z$$t = z.a$; z$$ = 1/2[z$$t, z$$b]; z$$b=z.a$$;
  penpos$$(linkw, angle(z.a$-z.a$$)/6 - 15);
  lnk$$ = z$$t .. z$$b cutbefore bbox pic$ cutafter bbox pic$$;
enddef;

def tseg(expr x) =
  z.a[x]r{up}..z.a[x]t{left}..z.a[x]l{down}
enddef;

def lseg(expr x) =
  z[x]l..z.a[x]l{down}
enddef;

def rseg(expr x) =
  z.a[x]r{up}..z[x]r
enddef;

def bseg(expr x) =
  z.a[x]b
enddef;

def fillet(expr x, y) =
  z.a[x]r{up}..1/2[z.a[x]tr, z.a[y]tl]{right}..z.a[y]l{down}
enddef;

def leapfrog(expr x, y, w) =
  z.a[y]r{up}..z[y].r
  ..7/8[1/2[z.a[y]t,z.a[w]t],z.a[x]b]
  ..z[w].l..z.a[w]l{down}
enddef;

vardef oval(expr x) =
  z.a[x]t..z.a[x]l..z.a[x]b..z.a[x]r..cycle
enddef;

vardef inst.lft(expr n)(text txt) =
  label.lft(txt, z.a[n]l);
enddef;

vardef inst.rt(expr n)(text txt) =
  label.rt(txt, z.a[n]r);
enddef;

vardef inst.ulft(expr n)(text txt) =
  label.ulft(txt, point 1/2 of oval(n));
enddef;

vardef inst.llft(expr n)(text txt) =
  label.llft(txt, point 3/2 of oval(n));
enddef;

vardef inst.lrt(expr n)(text txt) =
  label.lrt(txt, point 5/2 of oval(n));
enddef;

vardef inst.urt(expr n)(text txt) =
  label.urt(txt, point 7/2 of oval(n));
enddef;

vardef reg.lft(expr n)(text txt) =
  dotlabeldiam := regdot;
  if angle (direction 0 of lnk[n]) > -140:
    makelabel.lft(txt, z[n]);
  else:
    makelabel.ulft(txt, z[n]);
  fi
enddef;

vardef reg.rt(expr n)(text txt) =
  dotlabeldiam := regdot;
  if angle (direction 0 of lnk[n]) < -40:
    makelabel.rt(txt, z[n]);
  else:
    makelabel.urt(txt, z[n]);
  fi
enddef;

def begintree(expr n) =
  beginfig(n); picture pic[]; path lnk[];
enddef;

def drawtree(expr n) =
  for i = 1 upto n: draw pic[i]; endfor
  pickup pencircle scaled linkd;
  for i = 2 upto n: draw lnk[i]; endfor
enddef;
