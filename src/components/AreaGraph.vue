<template>
    <div class="opacity-50 absolute h-full w-full bg-sky-500" :style="areaGraphStyles"></div>
</template>

<script>
import Box from './Box.vue';

/** Represents a two dimensional graphical point, in a inverse-y cartesian plane */
class Point {
    constructor(x, y) {
        this.x = x;
        this.y = y;
    }
}

export default {
    name: "AreaGraph",
    components: { Box },
    props: {
        /**
         * An 1 dimensional array of numbers to graph.
         */
        data: {
            type: Array,
            required: true
        },

        /**
         * The Y value of the Y axis
         * If not provided, it will be calculated from the provided values
         * such that the min(data) == min
         */
        min: {
            type: Number,
            required: false
        },

        /**
         * The maximum value of the graph.
         * If not provided, it will be calculated from the provided values
         * such that the max(data) == max
         */
        max: {
            type: Number,
            required: false
        },

        /**
         * The quality of the bezier lines -- this controls how close each 
         * line segment is on the curve. Therefore a lower number == smooth curve
         * 
         * Range: [0, 1]
         * Warning: Extremely low values will cause significant performance hits.
         * Warning: Values out of bounds will cause undefined behaviour
         */
        step: {
            type: Number,
            required: false,
            default: 0.01
        }
    },

    computed: {
        /**
         * Scales the data to be within 0-100% depending on a min/max.
         * return --> Array:Point 
         */
        dataScaled() {
            // Append an extra point onto the end of the data, 
            // as the bezier tracing algorithm fails to curve on the final point,
            // so an extra point will mitigate this issue... eventually fix.
            const dataMimic = [...this.data, 0];
            // Calculate min if not provided.
            const min = this.min ? this.min : Math.min(...dataMimic);
            // Calculate max if not provided.
            const max = this.max ? this.max : Math.max(...dataMimic);
            // The range is the number of Y units between min and max
            const range = max - min;
            // The width of each point in the X axis.
            // 120% is used such that the fake final point exists the graph
            const xstep = 120 / (dataMimic.length - 1);
            // Notice, all x and y values are percentages.
            const ans = []
            for (let i=0; i<dataMimic.length; ++i) {
                ans.push(new Point(
                    i * xstep, // The X coordinate of the point.
                    100 - dataMimic[i] / range * 100 // 100 - Y_VALUE due to inverse Y system.
                ));
            }
            return ans;
        },

        /**
         * CSS Object for the graph.
         */
        areaGraphStyles() {
            return {
                clipPath: this.clipPathCSS,
            }
        },

        /**
         * Construct the polygon clip path string from a sequence of points,
         * representing a polyline.
         */
        clipPathCSS() {
            // Initial points are the points of the bottom-right, and bottom-left
            // respectively, which seal the graph bottom.
            let points = [new Point(100, 100), new Point(0, 100)];
            // Calculate the curve from the scaled data.
            let curve = this.getCurve(this.dataScaled);
            points = [...points, ...curve];
            let css_output = "polygon("
            for (let i=0; i<points.length; ++i) {
                css_output += `${points[i].x}% ${points[i].y}%`
                if (i != points.length - 1) {
                    css_output += ", ";
                }
            } css_output += ")";
            return css_output;
        }
    },

    methods: {
        /**
         * Returns a polyline of bezier.
         * @param {Point} p0 
         * @param {Point} p1 
         * @param {Point} p2 
         * @param {Point} p3 
         */
        bezier(p0, p1, p2, p3) {
            const polyline = []
            let lastPoint = p0;
            for (let t=this.step; t<=1; t+=this.step) {
                const c0x = Math.pow((1-t), 3)*p0.x;
                const c0y = Math.pow((1-t), 3)*p0.y;
                const c1x = 3*t*Math.pow((1-t), 2)*p1.x;
                const c1y = 3*t*Math.pow((1-t), 2)*p1.y;
                const c2x = 3*t*t*Math.pow((1-t), 1)*p2.x;
                const c2y = 3*t*t*Math.pow((1-t), 1)*p2.y;
                const c3x = t*t*t*p3.x;
                const c3y = t*t*t*p3.y;
                const px = c0x+c1x+c2x+c3x;
                const py = c0y+c1y+c2y+c3y;
                const currentPoint = new Point(px, py);
                polyline.push(lastPoint);
                lastPoint = currentPoint;
            } polyline.push(lastPoint);
            return polyline;
        },


        /**
         * Returns a polyline curve of the points list where the curve passes
         * through every single point on the curve.
         * @param {List:Point} pointsList 
         */
        getCurve(pointsList) {
            const rhsArray  = [];
            const a = [];
            const b = [];
            const c = [];

            // Generate linear equations
            for (let i=0; i<pointsList.length-1; ++i) {
                let rhsValueX = 0;
                let rhsValueY = 0;
                let p0 = pointsList[i];
                let p3 = pointsList[i+1];

                if (i == 0) {
                    a.push(0.0);
                    b.push(2.0);
                    c.push(1.0);
                    rhsValueX = p0.x + 2*p3.x;
                    rhsValueY = p0.y + 2*p3.y;
                } else if (i == pointsList.length - 2) {
                    a.push(2.0);
                    b.push(7.0);
                    c.push(0.0);
                    rhsValueX = 8*p0.x + p3.x;
                    rhsValueY = 8*p0.y + p3.y;
                } else {
                    a.push(1.0);
                    b.push(4.0);
                    c.push(1.0);
                    rhsValueX = 4*p0.x + 2*p3.x;
                    rhsValueY = 4*p0.y + 2*p3.y;
                }

                rhsArray.push(new Point(rhsValueX, rhsValueY));
            }
            
            // Solve the equations with Thomas algorithm
            for (let i=1; i<rhsArray.length; ++i) {
                let rhsValueX = rhsArray[i].x;
                let rhsValueY = rhsArray[i].y;
                let prevRhsValueX = rhsArray[i-1].x;
                let prevRhsValueY = rhsArray[i-1].y;
                let m = a[i]/b[i-1];
                let b1 = b[i]-m*c[i-1];
                b[i] = b1;
                let r2x = rhsValueX-m*prevRhsValueX;
                let r2y = rhsValueY-m*prevRhsValueY;
                rhsArray[i] = new Point(r2x, r2y);
            }

            // Get the first control points
            const firstControlPoints = [];
            while (firstControlPoints.length < rhsArray.length) firstControlPoints.push(null);
            let lastControlPointX = rhsArray[rhsArray.length-1].x/b[b.length-1];
            let lastControlPointY = rhsArray[rhsArray.length-1].y/b[b.length-1];
            firstControlPoints[firstControlPoints.length-1] = new Point(lastControlPointX, lastControlPointY);
            for (let i=rhsArray.length-2; i>=0; --i) {
                let nextControlPoint = firstControlPoints[i+1];
                let controlPointX = (rhsArray[i].x-c[i]*nextControlPoint.x)/b[i];
                let controlPointY = (rhsArray[i].y-c[i]*nextControlPoint.y)/b[i];
                firstControlPoints[i] = new Point(controlPointX, controlPointY);
            }

            // Get the second control points
            const secondControlPoints = [];
            for (let i=0; i<rhsArray.length; ++i) {
                if (i == rhsArray.length-1) {
                    let P3 = pointsList[i];
                    let P1 = firstControlPoints[i];
                    let controlPointX = (P3.x+P1.x)/2;
                    let controlPointY = (P3.y+P1.y)/2;
                    secondControlPoints.push(new Point(controlPointX, controlPointY));
                } else {
                    let P3 = pointsList[i+1];
                    let nextP1 = firstControlPoints[i+1];
                    let controlPointX = 2*P3.x-nextP1.x;
                    let controlPointY = 2*P3.y-nextP1.y;
                    secondControlPoints.push(new Point(controlPointX, controlPointY));
                }
            } 

            // Construct the bezier curves.
            let ans = [];
            for (let i=0; i<pointsList.length-1; ++i) {
                let p0 = pointsList[i];
                let p1 = firstControlPoints[i];
                let p2 = secondControlPoints[i];
                let p3 = pointsList[i+1];
                let subcurve = this.bezier(p0, p1, p2, p3);
                for (let i=0; i<subcurve.length; ++i) {
                    ans.push(subcurve[i]);
                }
            }
            return ans;
        }
    },
}
</script>
