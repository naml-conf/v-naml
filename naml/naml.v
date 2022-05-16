module naml

import os
import regex as re

pub type Any = bool | string | int | f64

// reads a naml config file and converts it to a map
// access values like so:
// `map['block.testBlock.testBool']` will yield `y` if using test.naml
pub fn read_file(file_name string) ?map[string]Any {

	file := os.read_file(file_name) or {
		panic('error reading file $file_name')
		return map[string]Any{}
	}

	mut naml := Naml{
		file: file
	}

	naml.tokenize()
	println(naml.tokens)
	return map[string]Any{}
}

struct Naml {	
mut:
	col    int
	row    int
	file   string
	tokens []Token
	blocks []string
	str    re.RE = re.regex_opt('".+"') ?
	ident  re.RE = re.regex_opt("[a-zA-Z][a-zA-Z]+ ") ?
	number re.RE = re.regex_opt("[0-9]+") ?
	double re.RE = re.regex_opt("[0-9]+([.][0-9]+)?") ?
}

enum TokenType {
	ident
	open
	close
	equal
	y
	n
	number
	str
}

struct Token {
	text string
	typ  TokenType
}

fn (mut n Naml) tokenize() {
	mut point := 0
	
	n.file = n.file.replace('\r\n', '\n')

	for n.file.len > 0 {
		point = n.match_token(point, n.file.len)
		n.file = n.file[point..]
		if n.file.starts_with('\n') { 
			n.row++
			n.col = 0
		} else {
			n.col++
		}

	}

}

fn (mut n Naml) match_token(point int, len int) int {

	match true {
		n.file.starts_with('{') {
			n.tokens << Token{'{', .open}
			return 1
		}
		n.file.starts_with('}') {
			n.tokens << Token{'}', .close}
			return 1
		}
		n.file.starts_with('=') {
			n.tokens << Token{'=', .equal}
			return 1
		}

		n.file.starts_with(' ') { return 1 }

		else {
			return n.regex_token()
		}
	}

	panic('this should not happen, ever!')
}

fn (mut n Naml) regex_token() int {
	s, t := n.str.find(n.file)
	if s != -1 {
		n.tokens << Token{n.file[..t], .str}
	}

	l, r := n.double.find(n.file)
	if l != -1 {
		n.tokens << Token{n.file[..r], .number}
		println(n.tokens.last())
		return r	
	}
	
	k, e := n.number.find(n.file)
	if k != -1 {
		n.tokens << Token{n.file[..e], .number}
		return e
	}

	j, w := n.ident.find(n.file)
	if j != -1 { 
		n.tokens << Token{n.file[..w], .ident}
		return w
	} else {
		panic('failed to match ident or value at $n.row:$n.col -> $n.file')
	}
}