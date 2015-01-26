#!/usr/bin/env python
import pygame
import sys
import os.path
import glob
import json
from pygame.locals import *

def load_areas(img, jsons):
    if img in jsons.keys():
        f = open(jsons[img], "r")
        img_json = f.read()
        f.close()
        parsed = json.loads(img_json)
        return parsed["area"]
    else:
        return []

if len(sys.argv) != 2:
    print "%s directory" % sys.argv[0]
    sys.exit()

RES = (1024, 768)

pygame.init()
fpsClock = pygame.time.Clock()

windowSurfaceObj = pygame.display.set_mode(RES)
pygame.display.set_caption("OpenQA needles viewer")

img_files = glob.glob(os.path.join(sys.argv[1], "*.png"))
img_files.sort()
json_files = glob.glob(os.path.join(sys.argv[1], "*.json"))

jsons = {}
for img in img_files:
    json_name = os.path.splitext(img)[0] + ".json"
    if json_name in json_files:
        jsons[img] = json_name

index = 0
imageSurfaceObj = pygame.image.load(img_files[index])
pygame.display.set_caption(os.path.basename(img_files[index]))
areas = load_areas(img_files[index], jsons)

while True:
    for event in pygame.event.get():
        if event.type == QUIT:
            pygame.quit()
            sys.exit()
        elif event.type == KEYDOWN:
            if event.key == K_LEFT:
                index = index - 1 if index > 0 else len(img_files) - 1
                img_index = img_files[index]
                imageSurfaceObj = pygame.image.load(img_index)
                pygame.display.set_caption(os.path.basename(img_index))
                areas = load_areas(img_index, jsons)
            elif event.key == K_RIGHT:
                index = index + 1 if index + 1 < len(img_files) else 0
                img_index = img_files[index]
                imageSurfaceObj = pygame.image.load(img_index)
                pygame.display.set_caption(os.path.basename(img_index))
                areas = load_areas(img_index, jsons)
            elif event.key == K_ESCAPE:
                pygame.event.post(pygame.event.Event(QUIT))

    windowSurfaceObj.blit(imageSurfaceObj, (0, 0))
    for area in areas:
        pygame.draw.rect(windowSurfaceObj, pygame.Color(255, 0, 0), (area["xpos"], area["ypos"], area["width"], area["height"]), 3)

    pygame.display.update()
    fpsClock.tick(30)
