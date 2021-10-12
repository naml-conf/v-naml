//module naml

import os 
import time

pub fn main() {

	mut token_list := []Token{}

	lines := os.read_lines('./test.naml') or {
		panic('error reading file test.naml')
		return
	}

	sw := time.new_stopwatch()

	//to keep track of which line we're on in case of error
	mut index := u16(0)

	for line in lines {
		index++
		match true {
			line.contains('{') {
				a, b := chop_up_block_open(line)
				c := a.trim(' ')
				token_list << Token{ Tokens.key, c }
				token_list << Token{ Tokens.block_open, b}
			}
			
			line.contains('}') {
				a := chop_up_block_close(line)
				c := a.trim(' ')
				token_list << Token{ Tokens.block_close, c }
			}

			line.contains('=') {
				a, b := chop_up(line)
				c := a.trim(' ')
				token_list << Token{ Tokens.key, c }
				trimmed_line := line.trim(' ')
				match true {
					b.contains('.') {
						if b.count('.') == 1 {
							token_list << Token{ Tokens.double, b }
						} else {
							panic("Extra . in double.\nAt line $index: $trimmed_line")
						}
					}

					b.contains('y') {
						if b.len == 1 {
							token_list << Token{ Tokens.bool_true, b }
						} else {
							panic("More than one character found when a boolean was expected (y|n)\nAt line $index: $trimmed_line")
						}
					}

					b.contains('"') {
						if b.count('"') == 2 {
							token_list << Token{ Tokens.text, b }
						} else {
							panic('Missing double quote in string\nAt line $index: $trimmed_line')
						}
					}

					b.contains_any('1234567890') {
						token_list << Token{ Tokens.integer, b}
					}

					b.contains('n') {
						if b.len == 1 {
							token_list << Token{ Tokens.bool_false, b }
						} else {
							panic("More than one character found when a boolean was expected (y|n)\nAt line $index: $trimmed_line")
						}
					}

					else {
						panic('Wrong value formatting encountered at\nAt line $index: $trimmed_line\n Please check if the value is correct') 
					}
				}
			}

			else { 
				trimmed_line := line.trim(' ')
				panic('Missing block open/close or value declaration\nAt line $index: $trimmed_line') 
			}
		}
	}

	println('Tokenized in ${f64(sw.elapsed().nanoseconds())/1000000.0}ms')

	mut token_map := map[string]TokenValue{}
	token_map['h'] = TokenValue(TokenMap{})
	nested_map := token_map['h'] or { panic('bad') }
	nested_map['h'] = 'h'

	println('Mapped in ${f64(sw.elapsed().nanoseconds())/1000000.0}ms')
}

enum Tokens {
    text		// ""
	block_open	// {
	block_close	// }
	integer		// i32
	double		// f64
	bool_true	// y
	bool_false	// n
	key			// name of a value
	equals		// an equals sign
}

type TokenValue = bool | string | int | f64 | TokenMap
type TokenMap = map[string]TokenValue

struct Token {
	token_type	Tokens
	value 		string
}


// this should only be used when we're sure there's a value being defined
fn chop_up(s string) (string, string) {
	return s.all_before(' ='), s.all_after('= ')
}

// chops up a block opening
fn chop_up_block_open(s string) (string, string) {
	return s.all_before(' {'), s.all_after_last(' ')
}

// chops up a block closing
fn chop_up_block_close(s string) (string) {
	return s
}

fn (t Token) str() string {
	return 'Token( type: $t.token_type, value: $t.value )'
}