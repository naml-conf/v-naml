import naml

import time

fn test_naml() {
	naml.read_file('./test.naml')
}

fn test_100_000 {
	for i in 0..100_000 {
		naml.read('./test.naml')
	}
}