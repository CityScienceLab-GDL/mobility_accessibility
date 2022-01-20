/**
* Name: GAMASimulation
*  
* Author: Gamaliel palomo
* Tags: 
*/


model GAMASimulation
import "core.gaml"

experiment simulacion type:gui{
	output{
		layout #split;
		display Scenario type:opengl  draw_env:false background:#black{
			species study_area aspect:default;
			species block aspect:default;
			species bus_stop aspect:default;
			species school aspect:default;
			species people aspect:default;
			species park aspect:default;
			species mobility_heatmap aspect:default;
			
		}
		display "indicators" type: java2D
		{
			chart "Indicadores"  label_font:font("Arial",11,#plain) legend_font:font("Arial",14,#bold) title_font:font("Arial",20,#bold ) background:#black  color:#white type: radar x_serie_labels: ["poblacion","numero de viviendas","viviendas habitadas","viviendas deshabitadas", "viviendas con electricidad","viviendas sin electricidad", "viviendas con internet", "acceso a la movilidad","densidad"] series_label_position: xaxis
			{
				data "Valor normalizado" value: [output_values[0],output_values[1],output_values[2],output_values[3],output_values[4],output_values[5],output_values[6],output_values[7],output_values[8]];
				/*data "numero de viviendas" value: mean(block collect(each.indicators["numero de viviendas"]));
				data "viviendas habitadas" value: mean(block collect(each.indicators["viviendas habitadas"]));
				data "viviendas deshabitadas" value: mean(block collect(each.indicators["viviendas deshabitadas"]));
				data "viviendas con electricidad" value: mean(block collect(each.indicators["viviendas con electricidad"]));
				data "viviendas sin electricidad" value: mean(block collect(each.indicators["viviendas sin electricidad"]));
				data "viviendas con internet" value: mean(block collect(each.indicators["viviendas con interenet"]));*/
			}

		}
	}
}