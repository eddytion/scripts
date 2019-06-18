from PIL import Image
from resizeimage import resizeimage
import os
import multiprocessing

files = []
for(dirpath, dirnames, filenames) in os.walk('/tmp/pics'):
    files.extend(filenames)
    break


def resize(pic):
        with open(pic, 'r+b') as f:
            with Image.open(f) as image:
                cover = resizeimage.resize_cover(image, [1280, 1024])
                cover.save(str(pic).split('.')[0] + '_new.' + str(pic).split('.')[1], image.format)


pool = multiprocessing.Pool(processes=multiprocessing.cpu_count()-1)
for i in files:
    pool.apply_async(resize, args=(i,))
pool.close()
pool.join()
