<template>
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
            <VueSlider class="mx-1" min="1" max="10" interval='0.1' v-model="n" />
          </div>
        </div>
      </div>
    </div>


    <div class="bg-slate-900 w-full p-10 rounded-b-md shadow-md" >
      <h2 class="tracking-wide text-slate-400 py-1 text-lg">CSS Code</h2>
      <h4 class="font-mono text-white text-xl overflow-hidden">
      {{clipPathCSS}}
     </h4>
    </div>
    
  </div>
</template>

<script>
import Box from './components/Box.vue';
import VueSlider from 'vue-slider-component'
import VueClipboard from 'vue-clipboard2'
import 'vue-slider-component/theme/antd.css'

export default {
  name: "App",
  components: {
    Box,
    VueSlider,
    VueClipboard
  },

  data () {
    return {
      n: 5
    }
  },

  methods: {
    RDP_Optimise(pointlist, epsilon) {
      
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
      const epsilon = 0.25;
      
      // Generate raw points.
      const all_points_list = [];
      for (let theta=0; theta<=2*Math.PI; theta+=precision) {
        const xp = 0.5 + Math.pow(Math.abs(Math.cos(theta)), 2.0/this.n) * 0.5*Math.sign(Math.cos(theta));
        const yp = 0.5 + Math.pow(Math.abs(Math.sin(theta)), 2.0/this.n) * 0.5*Math.sign(Math.sin(theta));
        all_points_list.push({
          x: xp,
          y: yp
        })
      }

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
