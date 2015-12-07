import std.experimental.ndslice;

/++
Params:
	image = изображение размерности `(h, w, c)`,
		где с - количество каналов в изображении
	nr = количество строк в окне
	nс = количество колонок в окне
Returns:
	изображение размерности `(h - nr + 1, w - nc + 1, c)`,
		где с - количество каналов в изображении.
		Гарантировано плотнаое размещение данных в памяти.
+/
Slice!(3, C*) byChannelMovingWindow(alias filter, C)
(Slice!(3, C*) image, size_t nr, size_t nc)
{
	import std.algorithm.iteration: map;
	import std.array: array;
	auto wnds = image        // 1. 3D : the last dimension is color channel 
		.pack!1              // 2. 2D of 1D : packs the last dimension
		.windows(nr, nc)     // 3. 2D of 2D of 1D : splits image to overlapping windows
		.unpack              // 4. 5D : unpacks windows
		.transposed!(0, 1, 4)// 5. 5D : brings color channel dimension to third position
		.pack!2;             // 6. 3D of 2D : packs the last two dimensions
	return wnds
		.byElement           // 7. Range of 2D : gets the range of all elements in `wnds`
		.map!filter          // 8. Range of C : 2D to C lazy conversion
		.array               // 9. C[] : sole memory allocation in this function
		.sliced(wnds.shape); //10. 3D : returns slice with corresponding shape
}

/++
Params:
	r = input range
	buf = буффер с длинной не менее количества элементов в `r`
Returns:
	медианное значение в рэндже `r`
+/
T median(Range, T)(Range r, T[] buf)
{
	import std.algorithm.sorting: sort;
	size_t n;
	foreach(e; r)
		buf[n++] = e;
	buf[0..n].sort();
	immutable m = n >> 1;
	return n & 1 ? buf[m] : cast(T)((buf[m-1] + buf[m])/2);
}

/++
Работает как с цветными так и с чернобелыми изображениями
+/
void main(string[] args)
{
	import imageformats; // can be found at code.dlang.org
	import std.conv, std.path, std.getopt;

	uint nr, nc, def = 3;
	auto helpInformation = args.getopt(
		"nr", "number of rows in window, default value is " ~ def.to!string, &nr, 
		"nc", "number of columns in window default value equals to nr", &nc);
	if(helpInformation.helpWanted)
	{
		defaultGetoptPrinter(
			"Usage: median-filter [<options...>] [<file_names...>]\noptions:", 
			helpInformation.options);
		return;
	}
	if(!nr) nr = def;
	if(!nc) nc = nr;

	auto buf = new ubyte[nr * nc];

	foreach(name; args[1..$])
	{
		IFImage image = read_image(name);

		auto ret = image.pixels
			.sliced(image.h, image.w, image.c)
			.byChannelMovingWindow
				!(window => median(window.byElement, buf))
				 (nr, nc);

		write_image(
			name.stripExtension ~ "_filtered.png",
			ret.length!1,
			ret.length!0,
			(&ret[0, 0, 0])[0..ret.elementsCount]);
	}
}
