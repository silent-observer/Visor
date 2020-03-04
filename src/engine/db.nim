import streams
import math, algorithm, endians
from sequtils import allIt
import glm/vec

const 
  StarMapCount = 500
  StarMapSphereRadius = 0.2

proc generatePoints(n: int): seq[Vec3f] =
  result.add(vec3f(0, 0, 1))
  for i in 1..n-2:
    let 
      u = float(i+6) / float(n + 11)
      v = i.float / 1.61803398875
      theta = arccos(2 * u - 1) - PI/2
      phi = TAU * v
      x = cos(theta) * cos(phi)
      y = cos(theta) * sin(phi)
      z = sin(theta)
    result.add(vec3f(x, y, z))
  result.add(vec3f(0, 0, -1))
const StarMapPoints = generatePoints(StarMapCount)

type 
  StarData* = object
    ra*: float64
    dec*: float64
    pos*: Vec3f
    mag*: int
    id*: int
    starClass*: array[2, char]
  StarMap* = object
    map*: array[StarMapCount, seq[StarData]]

proc findCellIndex(pos: Vec3f): int =
  var 
    minI = 0
    minD = distance(pos, StarMapPoints[0])
  for i, p in StarMapPoints:
    if distance(pos, p) < minD:
      minI = i
      minD = distance(pos, p)
  return minI

proc constructFromSourceData(filename: string): StarMap =
  var str = newFileStream(filename, fmRead)
  const header = [0, 1, 118218, 4, 1, -4, 38]
  for i in 0..6:
    var x = str.readInt32()
    var y: int32
    bigEndian32(y.addr, x.addr)
    if y != header[i]:
      echo "Error!"
      quit(1)
  for i in 1..118218:
    var data: StarData
    var a = str.readInt32()
    bigEndian32(data.id.addr, a.addr)
    var b: array[8, byte]
    discard str.readData(b.addr, 8)
    bigEndian64(data.ra.addr, b.addr)
    discard str.readData(b.addr, 8)
    bigEndian64(data.dec.addr, b.addr)

    let 
      x = cos(data.dec) * cos(data.ra)
      y = cos(data.dec) * sin(data.ra)
      z = sin(data.dec)
    data.pos = vec3f(x, y, z)
    data.dec = data.dec.radToDeg
    data.ra = data.ra.radToDeg

    discard str.readData(data.starClass.addr, 2)
    var c = str.readInt16()
    bigEndian16(data.mag.addr, c.addr)

    if data.mag >= 32768: data.mag -= 65536

    discard str.readInt16()
    discard str.readInt16()
    discard str.readInt16()
    discard str.readFloat32()
    discard str.readFloat32()
    if data.mag == 0: continue
    result.map[findCellIndex(data.pos)].add(data)
    if i mod 1000 == 0: echo i
  for i in 0..<StarMapCount:
    result.map[i].sort(proc(x, y: StarData): int = cmp(x.mag, y.mag), Descending)
  str.close()

proc writeStarMap(map: Starmap, filename: string) =
  var file = newFileStream(filename, fmWrite)
  for s in map.map:
    file.write(s.len)
    for data in s:
      file.write(data.ra)
      file.write(data.dec)
      file.write(data.pos.x)
      file.write(data.pos.y)
      file.write(data.pos.z)
      file.write(data.mag)
      file.write(data.id)
      file.write(data.starClass)

proc readStarMap*(filename: string): StarMap =
  var file = newFileStream(filename, fmRead)
  var minM = 100000
  var maxM = -100000
  for i in 0..<StarMapCount:
    let l = file.readInt32()
    result.map[i] = newSeqOfCap[StarData](l)
    for j in 0..<l:
      var d: StarData
      d.ra = file.readFloat64()
      d.dec = file.readFloat64()
      d.pos.x = file.readFloat32()
      d.pos.y = file.readFloat32()
      d.pos.z = file.readFloat32()
      d.mag = file.readInt32()
      
      minM = min(minM, d.mag)
      maxM = max(maxM, d.mag)
      d.id = file.readInt32()
      discard file.readData(d.starClass.addr, 2)
      result.map[i].add d
  echo minM, " ", maxM

proc isInFrontOfPlane(sphereCenter: Vec3f, normal: Vec3f): bool =
  let d = dot(sphereCenter, normal)
  return d > -StarMapSphereRadius

proc whichAreInsideRect*(normals: seq[Vec3f]): seq[int] =
  for i, p in StarMapPoints:
    let isInside = normals.allIt(isInFrontOfPlane(p, it))
    if isInside:
      result.add i

if isMainModule:
  #for p in StarMapPoints:
  #  echo p
  #echo StarMapPoints[233]
  let map = constructFromSourceData("data/hipparcos")
  for i in 0..<StarMapCount:
    var m = 0.0
    for d in map.map[i]:
      if distance(d.pos, StarMapPoints[i]) > m:
        m = distance(d.pos, StarMapPoints[i])
    echo i, " ", map.map[i].len, " ", m
  map.writeStarMap("data/stars.map")