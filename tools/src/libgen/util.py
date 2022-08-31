""" utilities """
import os
import os.path as path
import fnmatch
import re

def sorted_alphanumeric(data):
	convert = lambda text: int(text) if text.isdigit() else text.lower()
	alphanum_key = lambda key: [convert(c) for c in re.split('([0-9]+)', key)]
	return sorted(data, key=alphanum_key)

def get_files(sourcePath):

	files = []

	if sourcePath is None:
		return files

	if path.isfile(sourcePath):
		files.append(sourcePath)
		return files
	else:
		sourcePattern = "*"

		if not path.isdir(sourcePath):
			parts = path.split(sourcePath)
			sourcePath = parts[0]
			sourcePattern = parts[1]

		for file in os.listdir(sourcePath):
			if fnmatch.fnmatch(file, sourcePattern):
				files.append(path.join(sourcePath, file))

	return sorted_alphanumeric(files)
