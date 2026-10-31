import { describe, expect, it } from "vitest";
import { fitCameraDistance, thinnestAxis } from "./coin-scene";

describe("coin scene helpers", () => {
  it("fits wider than tall views by the vertical FOV, tall views by the horizontal FOV", () => {
    const wide = fitCameraDistance(1, 35, 2);
    const square = fitCameraDistance(1, 35, 1);
    const tall = fitCameraDistance(1, 35, 0.5);
    expect(wide).toBeCloseTo(square, 6);
    expect(tall).toBeGreaterThan(square);
  });
  it("detects the coin's thin axis", () => {
    expect(thinnestAxis({ x: 540, y: 540, z: 54 })).toBe("z");
    expect(thinnestAxis({ x: 0.49, y: 0.05, z: 0.49 })).toBe("y");
    expect(thinnestAxis({ x: 0.05, y: 0.5, z: 0.5 })).toBe("x");
  });
});
