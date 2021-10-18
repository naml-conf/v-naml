module naml

import os {read_lines}

pub fn naml(file_name string) &NamlBlock {

	mut token_list := []Token{}
	lines := os.read_lines(file_name) or {
		panic('error reading file $file_name')
		return &NamlBlock{'null', []&NamlNode{}}
	}

	tokenize(lines, mut token_list)
	return parse(mut token_list)

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

struct NamlBlock {
	name	string
mut:
	block	[]&NamlNode
}

struct Token {
	token_type	Tokens
	value 		string
}

type NamlData = string | bool | int | f64

struct NamlValue{
	name		string
	content		NamlData
	value		DataType
}

type NamlNode = NamlValue | NamlBlock

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
}

[inline]
fn parse(mut token_list []Token) &NamlBlock {
	
	mut block_stack := []&NamlBlock{}
	mut node_stack := []&NamlNode{}
	mut root_node :=  &NamlBlock{ 'root', []&NamlNode{} }
	node_stack << root_node
	block_stack << root_node

	for i, token in token_list {

		mut current_block := block_stack.last()

		match token.token_type {

			.integer {
				current_block.add_child(&NamlValue{ token_list[i-1].value, token.value.int(), DataType.int })
			}

			.text {
				current_block.add_child(&NamlValue{ token_list[i-1].value, token.value.substr(1, token.value.len-1), DataType.string })
			}
			
			.block_open {
				new_block := &NamlBlock{token_list[i-1].value, []&NamlNode{}}
				block_stack << new_block
			}

			.double {
				current_block.add_child(&NamlValue{ token_list[i-1].value, token.value.f64(), DataType.f64 })
			}

			.bool_false {
				current_block.add_child(&NamlValue{ token_list[i-1].value, false, DataType.bool })
			}

			.bool_true {
				current_block.add_child(&NamlValue{ token_list[i-1].value, true, DataType.bool })
			}

			.block_close {
				block_stack[block_stack.len-2].block << current_block
				block_stack.pop()
			}

			.key {
				continue
			}
		}
	}

	return root_node

}

fn (mut b NamlBlock) add_child(n &NamlNode) {
	b.block << n
}