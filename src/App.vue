<template>
  <div>
    <div class="container my-10 mx-auto rounded-md bg-white shadow-md flex flex-col items-center">
      <div class="px-14 py-8">
        <h1 class="text-3xl text-slate-900 font-bold tracking-wide">Pure CSS Smoothed Corners Implementation</h1>
        <div class="my-12 items-center flex md:flex-row md:gap-x-10 flex-col gap-y-10">
          <Box :style="boxStyles"/>
          <div class="flex flex-col">
            <div>
              <h2 class='text-2xl text-slate-600'>n is 
                <input min=1 class="focus:border-none focus:outline-none appearance-none" type="number" v-model="n">
              </h2>
              <p class="text-md py-2 text-slate-500">n controls how smooth the corners are</p>
              <VueSlider class="mx-1" v-model="n" />
            </div>
          </div>
        </div>
      </div>


      <div class="cursor-pointer bg-slate-900 w-full p-10 rounded-b-md shadow-md" >
        <h2 class="tracking-wide text-slate-400 py-1 text-lg">CSS Code</h2>
        <h4 @click="$event.target.select()" class="font-mono text-white text-xl overflow-hidden whitespace-nowrap">
        clip-path: {{clipPathCSS}};
        </h4>
      </div>
      
    </div>

    <div class="relative w-full h-64 my-10 mx-auto rounded-md bg-white shadow-md flex items-stretch">
      <div class="p-5 w-80">
         <h1 class="text-xl font-bold">Pure CSS Curved Area Graph</h1>
         <p class="text-sm">Constructed using a poly-cubic-bezier curve, and drawn with polylines in a divide and conquer algorithm.</p>
      </div>
     
      
      <AreaGraph :min="0" :max="10" :data="data1" />
      <AreaGraph :min="0" :max="10" :data="data2" />
    </div> 
    
  </div>

  
</template>

<script>
import Box from './components/Box.vue';
import AreaGraph from './components/AreaGraph.vue';
import VueSlider from 'vue-slider-component'
import VueClipboard from 'vue-clipboard2'
import 'vue-slider-component/theme/antd.css'

export default {
  name: "App",
  components: {
    Box,
    AreaGraph,
    VueSlider,
    VueClipboard,
  },

  data () {
    return {
      n: 5,
      data1: [3, 3, 2, 6, 5.5, 5.5, 0],
      data2: [2, 4, 4, 4, 4.5, 9],
    }
  },

  methods: {
    /**
     * Given 3 points l1, l2, p.
     * Where l1 --> l2 form a line.
     * Find the perpendicular (closest) distance from l1-->l2 to p.
     */
    perpDistance(l1, l2, p) {
      const numerator = Math.abs((l2.x-l1.x)*(l1.y-p.y)-(l2.y-l1.y)*(l1.x-p.x));
      const denominator = Math.sqrt((l2.x-l1.x)*(l2.x-l1.x) + (l2.y-l1.y)*(l2.y-l1.y));
      return numerator / denominator;
    },
    
    /**
     * Ramer-Douglas-Peucker algorithm.
     * 
     * This function takes a list of lines (a polyline), and given a threshold,
     * it will divide and conquer to merge the lines into a lower resolution line.
     */
    RDP_Optimise(pointlist, epsilon) {
      if (pointlist.length < 2) { 
        return pointlist; 
      }

      // Find the point with the maximum distance between the line from the start-->end
      const start = pointlist[0]; 
      const end = pointlist[pointlist.length-1];
      let dmax = 0;
      let dmax_index = 0;
      for (let i=1; i<pointlist.length-1; ++i) {
        let dist = this.perpDistance(start, end, pointlist[i]);
        if (dist > dmax) {
          dmax = dist;
          dmax_index = i;
        }
      }

      // If the maxmimum distance is > epsilon recursively simplify.
      // as the point must be kept.
      let result = [];
      if (dmax > epsilon) {
        const res1 = this.RDP_Optimise(pointlist.slice(0, dmax_index), epsilon);
        const res2 = this.RDP_Optimise(pointlist.slice(dmax_index, pointlist.length), epsilon);
        result = [...res1, ...res2];
      }   
      
      // Otherwise, it must be able to removed.
      else {
        result.push(start);
        result.push(end);
      }

      return result;
    }
  },

  computed: {
    clipPathCSS() {
      const width   = 1;
      const height  = 1;
      const x0      = width / 2.0;
      const y0      = height / 2.0;
      const r       = width / 2.0;
      
      // Important parameters
      const precision = 0.01;
      const epsilon = 0.0001;
      
      // Generate raw points.
      let all_points_list = [];
      for (let theta=0; theta<=2*Math.PI; theta+=precision) {
        const xp = 0.5 + Math.pow(Math.abs(Math.cos(theta)), 2.0/this.n) * 0.5*Math.sign(Math.cos(theta));
        const yp = 0.5 + Math.pow(Math.abs(Math.sin(theta)), 2.0/this.n) * 0.5*Math.sign(Math.sin(theta));
        all_points_list.push({
          x: xp,
          y: yp
        })
      }

      // Compress
      all_points_list = this.RDP_Optimise(all_points_list, epsilon);
      
      // Create the css
      let css_output = "polygon("
      for (let i=0; i<all_points_list.length - 1; ++i) {
        let point = all_points_list[i];
        css_output += (100*point.x + "% " + 100*point.y + "%" + ", ");
      } 
      
      css_output += (100*(all_points_list[all_points_list.length-1].x) + "% " 
                 + (all_points_list[all_points_list.length-1].y) * 100 + "%" + ")");
      
      return css_output;
    },

    boxStyles() {
      return {
        clipPath: this.clipPathCSS,
      }
    }
  }
};
</script>
