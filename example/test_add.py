import unittest
import add

class AdditionTestCase(unittest.TestCase):
    def test_add_takes_two_arguments_and_return_the_sum(self):
        x, y = 3, 2
        self.assertEqual(add.add(x,y), x+y)

    def test_add_can_take_multiple_arguments(self):
        self.assertEqual(add.add(1,2,3,4,5), 15)

