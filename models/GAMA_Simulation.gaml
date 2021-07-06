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
			species block aspect:default;
			species bus_stop aspect:default;
		}
		display "indicators" type: java2D
		{
			chart "Indicadores" type: radar x_serie_labels: ["poblacion","numero de viviendas","viviendas habitadas","viviendas deshabitadas", "viviendas con electricidad","viviendas sin electricidad", "viviendas con internet"] series_label_position: xaxis
			{
				data "Valor normalizado" value: [
					mean(block collect(each.indicators["poblacion"]/blocks_max_values["poblacion"])), 
					blocks_max_values["numero de viviendas"]>0?mean(block collect(each.indicators["numero de viviendas"]/blocks_max_values["numero de viviendas"])):0, 
					blocks_max_values["viviendas habitadas"]>0?mean(block collect(each.indicators["viviendas habitadas"]/blocks_max_values["viviendas habitadas"])):0, 
					blocks_max_values["viviendas deshabitadas"]>0?mean(block collect(each.indicators["viviendas deshabitadas"]/blocks_max_values["viviendas deshabitadas"])):0, 
					blocks_max_values["viviendas con electricidad"]>0?mean(block collect(each.indicators["viviendas con electricidad"]/blocks_max_values["viviendas con electricidad"])):0,
					blocks_max_values["viviendas sin electricidad"]>0?mean(block collect(each.indicators["viviendas sin electricidad"]/blocks_max_values["viviendas sin electricidad"])):0,
					blocks_max_values["viviendas con interenet"]>0?mean(block collect(each.indicators["viviendas con interenet"]/blocks_max_values["viviendas con interenet"])):0
				];
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