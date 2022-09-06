
""" convert an rgb (0-255) color components to a genesis 12-bit color. """
def make_color(r, g, b):
	r = int(r / 255.0 * 15)
	g = int(g / 255.0 * 15)
	b = int(b / 255.0 * 15)
	return b << 8 | g << 4 | r

""" build a 16-bit tile value. """
def make_tile(tileId, hFlip=0, vFlip=0, palette=0, priority=0):
	# Tile Attributes (Genesis)
	# 2 Bytes Per Tile
	# 15 14 13 12 11 10 09 08 07 06 05 04 03 02 01 00
	# PR P1 P0 VF HF TT T9 T8 T7 T6 T5 T4 T3 T2 T1 T0 
	#  T0 - TT : Tile Number
	#       HF : Horizontal Flip
	#       VF : Vertical Flip
	#  P0 - P1 : Palette Number
	#       PR : Prioirty
	return priority << 14 | palette << 13 | vFlip << 12 | hFlip << 11 | tileId
