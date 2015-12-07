import std.algorithm: each;
import std.experimental.ndslice;
void main() {
	foreach(s, selection; [[size_t(2), 3], [size_t(2), 3, 6, 7]])
	{
		enum h = 128 * 8;
		auto data = new ubyte[h*h];
		auto b = data
			.sliced(h, h)
			.blocks(16, 16)
			.blocks(2, 2)
			.blocks(4, 4)
			.unpack
			.transposed(selection)
			.pack!4;
		foreach(i; 0..4) foreach(j; 0..4) {
			auto c = b[i, j];
			if(i % 2) c = c.reversed!0;
			if(j % 2) c = c.reversed!1;
			c.allDropOne
				.byElementInStandardSimplex
				.each!(a  => a[] = ubyte.max);
			c.allReversed
				.diagonal
				.strided!0(2)
				.unpack[] = ubyte.max;
		}
		import imageformats, std.conv;
		write_image(s.to!string ~ ".png", h, h, data, ColFmt.Y);
	}
}
