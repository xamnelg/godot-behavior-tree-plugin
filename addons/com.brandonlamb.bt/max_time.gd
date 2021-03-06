extends "res://addons/com.brandonlamb.bt/root.gd"

################
# The MIT License (MIT)
#
# Copyright (c) 2016 Jeffery Olson <olson.jeffery@gmail.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

const BehvError = preload("res://addons/com.brandonlamb.bt/error.gd")

export(int) var max_calls = 0

var total_calls = 0

# Decorator Node
func tick(actor, ctx):
	if get_child_count() > 1:
		return BehvError.new(self, "ERROR BehaviorMaxTime has more than one child")

	if total_calls >= max_calls:
		return FAILED

	# 0..1 children
	for c in get_children():
		total_calls++

		if c.disabled:
			return FAILED

		return c.tick(actor, ctx)

	return FAILED
