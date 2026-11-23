// A comment.
const re = /\/\/ not a comment/g;
const t = `template /* not a comment */ ${x}`;
const s = '// not a comment';
/* block
   comment */
const d = a / b; // division, then a comment
function f() {
  return /\/*/.test(s);
}
