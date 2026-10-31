/** Camera distance that fits a sphere of `radius` inside a view with vertical FOV `fovDeg` and the given aspect ratio. */
export function fitCameraDistance(radius: number, fovDeg: number, aspect: number, margin = 1.15): number {
  const vFov = (fovDeg * Math.PI) / 180;
  const hFov = 2 * Math.atan(Math.tan(vFov / 2) * aspect);
  const fov = Math.min(vFov, hFov); // the tighter dimension decides
  return (radius / Math.sin(fov / 2)) * margin;
}

/** Which model axis is the thinnest (the coin's thickness / face normal). */
export function thinnestAxis(size: { x: number; y: number; z: number }): "x" | "y" | "z" {
  if (size.x <= size.y && size.x <= size.z) return "x";
  if (size.y <= size.x && size.y <= size.z) return "y";
  return "z";
}
