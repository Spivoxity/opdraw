% optrees.mp

numeric gridx, gridy; gridx = gridy = 36pt;
numeric odx, ody; odx = 6pt; ody = 12pt;
numeric linkoff.l, linkoff.v, linkoff.r;
linkoff.l = -0pt; linkoff.v = 0pt; linkoff.r = 0pt;

numeric linkw; linkw = 24pt;

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
  pic@# = p shifted (z.a@# - center p);
enddef;

vardef link@#(suffix $, $$) =
  z$$t = z.a$+(linkoff@#, 0); z$$ = 1/2[z$$t, z$$b]; z$$b=z.a$$;
  penpos$$(linkw, 0);
  lnk$$ = z$$t .. z$$b cutbefore bbox pic$ cutafter bbox pic$$;
enddef;

vardef mypath@#(expr x)(text txt) =
  z.a[x]@#{down}
    for i=txt:
      ..z[i]@#
      ..z.a[i]@#{down}
    endfor
enddef;

vardef oval(expr x) =
  z.a[x]t..z.a[x]l..z.a[x]b..z.a[x]r..cycle
enddef;

vardef chain(expr x)(text txt) =
  save y_;
  for yy = txt: y_ := yy; endfor
  z.a[x]t{left}..mypath.l(x, txt)..z.a[y_]b{right}
    ..reverse mypath.r(x, txt)..cycle
enddef;

vardef inst.lft(expr n)(text txt) =
  label.lft(txt, z.a[n]l)
enddef;

vardef inst.rt(expr n)(text txt) =
  label.rt(txt, z.a[n]r)
enddef;

vardef inst.ulft(expr n)(text txt) =
  label.ulft(txt, point 1/2 of oval(n))
enddef;

vardef inst.llft(expr n)(text txt) =
  label.llft(txt, point 3/2 of oval(n))
enddef;

vardef inst.lrt(expr n)(text txt) =
  label.lrt(txt, point 5/2 of oval(n))
enddef;

vardef inst.urt(expr n)(text txt) =
  label.urt(txt, point 7/2 of oval(n))
enddef;

vardef reg.lft(expr n)(text txt) =
  dotlabeldiam := 4pt;
  if angle (direction 0 of lnk[n]) > -140:
    makelabel.lft(txt, z[n])
  else:
    makelabel.ulft(txt, z[n])
  fi
enddef;

vardef reg.rt(expr n)(text txt) =
  dotlabeldiam := 4pt;
  if angle (direction 0 of lnk[n]) < -40:
    makelabel.rt(txt, z[n])
  else:
    makelabel.urt(txt, z[n])
  fi
enddef;

def begintree(expr n) = beginfig(n); picture pic[]; path lnk[]; enddef;

def drawtree(expr n) =
  for i = 1 upto n: draw pic[i]; endfor
  pickup pencircle scaled 1.2;
  for i = 2 upto n: draw lnk[i]; endfor
enddef;
