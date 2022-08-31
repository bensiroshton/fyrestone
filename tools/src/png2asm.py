"""convert png into assembly."""
import sys
import os
import json
import os.path as path
import libgen

log = libgen.Log("png2asm.log")

def process(options):

	info = {}
	info["jobs"] = []

	os.makedirs(options["outFolder"], exist_ok=True)

	# process each source image
	sourcePath = options["sources"]

	files = libgen.util.get_files(options["sources"])

	for file in files:
		info["jobs"].append(libgen.png.to_asm(file, options))

	return info

def show_help():

	log.println("png2asm -i [source image(s)]")
	log.println("-i      : source image(s) to process, wildcards are ok. [REQUIRED]")
	log.println("-o      : output folder [default current directory].")
	log.println("-w      : enable overwrite mode [default: False].")
	log.println("-nodata : don't write tile data [default: include].")
	log.println("-nopal  : don't write palette data [default: include].")

def main(argv):

	options = {}
	options["log"] = log
	options["outFolder"] = "."
	options["name"] = None
	options["overwrite"] = False
	options["sources"] = None
	options["includeData"] = True
	options["includePalette"] = True

	argCount = len(argv)
	if argCount==1: # need _some_ arguments
		show_help()
		return

	testMode = False

	xr = iter(range(argCount))
	next(xr)
	for i in xr:
		arg = argv[i]
		if arg=="-o" and i<argCount - 1:
			options["outFolder"] = argv[i+1]
			next(xr)
		elif arg=="-i" and i<argCount - 1:
			options["sources"] = argv[i+1]
			next(xr)
		elif arg=="-w":
			options["overwrite"] = True
		elif arg=="-nodata":
			options["includeData"] = False
		elif arg=="-nopal":
			options["includePalette"] = False
		elif arg=="-h":
			show_help()
			return
		else:
			log.println("unrecognized command (or missing command arguments): " + arg)
			return

	if options["sources"] is None:
		log.println("source image(s) must be supplied.")
		return

	if not options["includeData"] and not options["includePalette"]:
		log.println("not including data or palette, nothing to do.")
		return

	options["outFolder"] = path.abspath(options["outFolder"])

	json.dump(options, log.file(), indent=4)
	log.println("")

	info = process(options)

	if info is not None:
		with open("png2asm.json", "w") as f:
			json.dump(info, f, indent=4)

	log.println("finished.")

if __name__ == '__main__':

	try:
		main(sys.argv)
	except KeyboardInterrupt:
		log.println("\nuser break!")
	except SystemExit:
		log.println("exiting program.")
	#except:		
	#	log.println(f"Unexpected error: {sys.exc_info()[0]}")

	log.close()
