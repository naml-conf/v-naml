//module naml

import os 
import time

pub fn main() {

	mut token_list := []Token{}

	lines := os.read_lines('./test.naml') or {
		panic('error reading file test.naml')
		return
	}

	//for i in 0 .. 5 {
	tokenize(lines, mut token_list)
	//	println(i)
	//}

	parse(mut token_list)

	// for b in blub {
	// 	println(b.name +', '+ b.content.str())
	// }

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
}

enum DataType{
	string
	int
	f64
	bool
	block
}

struct Block {
mut:
	block []&NamlNode
}

struct Token {
	token_type	Tokens
	value 		string
}

type NamlData = string | bool | int | f64 | Block

struct NamlNode{
	name		string
	content		NamlData
	value		DataType
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

[inline]
fn tokenize(lines []string, mut token_list []Token) {
	sw := time.new_stopwatch()

	//to keep track of which line we're on in case of error
	mut index := u16(0)

	for line in lines {
		index++
		trimmed_line := line.trim(' ')
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
				panic('Missing block open/close or value declaration\nAt line $index: $trimmed_line') 
			}
		}
	}

	println('Tokenized in ${f64(sw.elapsed().nanoseconds())/1000000.0}ms')
}

[inline]
fn parse(mut token_list []Token) {

	sw := time.new_stopwatch()

	mut root_node :=  Block{}
	//mut current_node := 
	mut depth_index := 0

	for i, token in token_list {
		typ := token.token_type

		if depth_index > 0 {
			
		}

		match typ {

			.integer {
				root_node.add_child(&NamlNode{ token_list[i-1].value, token.value.int(), DataType.int })
			}

			.text {
				root_node.add_child(&NamlNode{ token_list[i-1].value, token.value.substr(1, token.value.len-1), DataType.string })
			}
			
			.block_open {
				root_node.add_child(&NamlNode{ token_list[i-1].value, Block{}, DataType.block })
			}

			.double {
				root_node.add_child(&NamlNode{ token_list[i-1].value, token.value.f64(), DataType.f64 })
			}

			.bool_false {
				root_node.add_child(&NamlNode{ token_list[i-1].value, false, DataType.bool })
			}

			.bool_true {
				root_node.add_child(&NamlNode{ token_list[i-1].value, true, DataType.bool })
			}

			.block_close {

			}

			else {
				do_nothing()
			}
		}
	}

	println('Mapped in ${f64(sw.elapsed().nanoseconds())/1000000.0}ms')
	println(root_node.block)

}

fn do_nothing() { }

fn (mut b Block) add_child(n &NamlNode) {
	b.block << n
}