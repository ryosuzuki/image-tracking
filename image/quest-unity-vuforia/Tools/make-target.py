#!/usr/bin/env python3
"""Generate an authored, asymmetric feature-rich target; no camera/private pixels."""
from pathlib import Path
import random
from PIL import Image, ImageDraw
randomizer = random.Random(81023)
image = Image.new("RGB", (1000, 700), "white")
draw = ImageDraw.Draw(image)
draw.rectangle((15, 15, 985, 685), outline="black", width=7)
draw.text((40, 35), "PAPERLAB - VUFORIA IMAGE TARGET - 20 cm wide", fill="black")
for n in range(150):
    x, y = randomizer.randrange(35, 945), randomizer.randrange(90, 645)
    radius = randomizer.randrange(4, 20)
    color = randomizer.choice(["black", "navy", "darkgreen", "maroon"])
    if n % 3 == 0:
        draw.polygon([(x,y-radius),(x-radius,y+radius),(x+radius,y+radius)], fill=color)
    elif n % 3 == 1:
        draw.rectangle((x-radius,y-radius,x+radius,y+radius), outline=color, width=3)
    else:
        draw.line((x-radius,y-radius,x+radius,y+radius,x-radius,y+radius), fill=color, width=4)
    draw.text((x+radius+3, y), str(n), fill="black")
output = Path(__file__).resolve().parents[1] / "Assets/Resources/paper-target.png"
output.parent.mkdir(parents=True, exist_ok=True)
image.save(output)
print(output.name)
