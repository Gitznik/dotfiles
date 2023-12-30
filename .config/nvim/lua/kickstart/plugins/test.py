# Simple progam with a class and a function


class PointXY:
    def __init__(self, x, y):
        self.x = x
        self.y = y

    def print(self):
        print(f"({self.x}, {self.y})")

    def __eq__(self, other):
        return self.x == other.x and self.y == other.y

    def __gt__(self, other):
        return self.x > other.x and self.y > other.y

    def __lt__(self, other):
        return self.x < other.x and self.y < other.y


def main():
    p1 = PointXY(1, 2)
    p2 = PointXY(2, 3)
    p3 = PointXY(1, 2)

    p1.print()
    p2.print()
    p3.print()

    print(p1 == p2)
    print(p1 == p3)
    print(p1 > p2)
    print(p1 < p2)
    print(p1 < p3)


if __name__ == "__main__":
    main()
