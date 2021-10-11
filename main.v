//module naml

import os 

fn main() {

	mut token_list := []Token{}

	lines := os.read_lines('./test.naml') or {
		panic('error reading file test.naml')
		return
	}

	for line in lines {
		//TODO make it find the correct type
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
				token_list << Token{ Tokens.key, c}

				match true {
					b.contains('.') {
						token_list << Token{ Tokens.double, b }
					}

					b.contains('y') {
						token_list << Token{ Tokens.bool_true, b }
					}

					b.contains('n') {
						token_list << Token{ Tokens.bool_false, b }
					}

					b.contains('"') {
						token_list << Token{ Tokens.text, b }
					}

					b.contains_any('1234567890') {
						token_list << Token{ Tokens.integer, b}
					}

					else { panic('Wrong value!') }
				}
			}
			else { panic('Parse error!') }
		}
	}

	for token in token_list {
		println(token.str())
	}
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