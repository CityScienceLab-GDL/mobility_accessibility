/**
* Name: Complex Road Network 
* Author: Patrick Taillandier, Gamaliel Palomo (adaptation to CityScope@GDL)
* Description: Model to show how to use the driving skill to represent the traffic on a road network imported from shapefiles (generated, for the city, with 
* OSM Loading Driving), with intersections and traffic lights going from red to green to let people move or stop. Two experiments are presented : one concerning a 
* a simple ring network and the other a real city network.
* Tags: gis, shapefile, graph, agent_movement, skill, transport
*/

/*
 * HISTORY
 * gama-issue14-may08 Work on integration between Traffic model and CityScope. Now when a person needs to move due to the scheduler, it creates a car agent which makes de driving behavior.
 */
 
 
model RoadTrafficComplex
import "constants.gaml"
import "CityScope.gaml"

global {
	bool  display3D<- false;
	
	//Check if we use simple data or more complex roads
	file shape_file_roads <-  file("../includes/shp/events/roads.shp");
	file shape_file_nodes <- file("../includes/shp/events/nodes.shp");
	geometry shape <- envelope(shape_file_roads) + 50.0;
	graph road_network;
	int nb_people <- 200;

	init {
	//create the intersection and check if there are traffic lights or not by looking the values inside the type column of the shapefile and linking
	// this column to the attribute is_traffic_signal. 
		create intersection from: shape_file_nodes with: [is_traffic_signal::(read("type") = "traffic_signals")];

		//create road agents using the shapefile and using the oneway column to check the orientation of the roads if there are directed
		create road from: shape_file_roads with: [num_lanes::int(read("lanes")), oneway::string(read("oneway"))] {
			num_lanes <- num_lanes<=0?1:num_lanes;
			geom_display <- shape + (2.5 * num_lanes);
			maxspeed <- (num_lanes = 1 ? 30.0 : (num_lanes = 2 ? 50.0 : 70.0)) °km / °h;
			switch oneway {
				match "no" {
					create road {
						num_lanes <- max([1, int(myself.num_lanes / 2.0)]);
						shape <- polyline(reverse(myself.shape.points));
						maxspeed <- myself.maxspeed;
						geom_display <- myself.geom_display;
						linked_road <- myself;
						myself.linked_road <- self;
					}

					num_lanes <- int(num_lanes / 2.0 + 0.5);
				}

				match "-1" {
					shape <- polyline(reverse(shape.points));
				}

			}

		}

		map general_speed_map <- road as_map (each::(each.shape.perimeter / each.maxspeed));

		//creation of the road network using the road and intersection agents
		road_network <- (as_driving_graph(road, intersection)) with_weights general_speed_map;

		//initialize the traffic light
		ask intersection {
			do initialize;
		}

	}

}

//species that will represent the intersection node, it can be traffic lights or not, using the skill_road_node skill
species intersection skills: [skill_road_node] {
	bool is_traffic_signal;
	list<list> stop;
	int time_to_change <- 100;
	int counter <- rnd(time_to_change);
	list<road> ways1;
	list<road> ways2;
	bool is_green;
	rgb color_fire;

	action initialize {
		if (is_traffic_signal) {
			do compute_crossing;
			stop << [];
			if (flip(0.5)) {
				do to_green;
			} else {
				do to_red;
			}

		}

	}

	action compute_crossing {
		if (length(roads_in) >= 2) {
			road rd0 <- road(roads_in[0]);
			list<point> pts <- rd0.shape.points;
			float ref_angle <- float(last(pts) direction_to rd0.location);
			loop rd over: roads_in {
				list<point> pts2 <- road(rd).shape.points;
				float angle_dest <- float(last(pts2) direction_to rd.location);
				float ang <- abs(angle_dest - ref_angle);
				if (ang > 45 and ang < 135) or (ang > 225 and ang < 315) {
					ways2 << road(rd);
				}

			}

		}

		loop rd over: roads_in {
			if not (rd in ways2) {
				ways1 << road(rd);
			}

		}

	}

	action to_green {
		stop[0] <- ways2;
		color_fire <- #green;
		is_green <- true;
	}

	action to_red {
		stop[0] <- ways1;
		color_fire <- #red;
		is_green <- false;
	}

	reflex dynamic_node when: is_traffic_signal {
		counter <- counter + 1;
		if (counter >= time_to_change) {
			counter <- 0;
			if is_green {
				do to_red;
			} else {
				do to_green;
			}

		}

	}

	aspect default {
		if (display3D) {
			if (is_traffic_signal) {
				draw box(1, 1, 10) color: #black;
				draw sphere(3) at: {location.x, location.y, 10} color: color_fire;
			}
		} else {
			if (is_traffic_signal) {
				draw circle(5) color: color_fire;
			}
		}	
	}
}

//species that will represent the roads, it can be directed or not and uses the skill skill_road
species road skills: [skill_road] {
	geometry geom_display;
	string oneway;

	aspect default {
		if (display3D) {
			draw geom_display color: #lightgray;
		} else {
			draw shape color: #white end_arrow: 5;
		}
		
	}

}

//Car species that will move on the graph of roads to a target and using the driving skill
species car skills: [advanced_driving] {
	
	rgb color <- rnd_color(255);
	int counter_stucked <- 0;
	int threshold_stucked;
	bool breakdown <- false;
	float proba_breakdown;
	intersection target;												//gama-issue14-may08->
	point target_point;
	blocks target_block;
	bool to_be_killed <- false;
	bool is_visible <- false;
	
	list<intersection> tested_targets <- [];
	list<intersection> tested_locations <- [];
	
	string mobility_type;										//<-gama-issue14-may08
	
	reflex breakdown when: flip(proba_breakdown) {
		breakdown <- true;
		max_speed <- 1 #km / #h;
	}
	reflex time_to_go when: final_target = nil {																					//gama-issue14-may08->
		using topology(world){
			target_point <- any_location_in(target_block);
			target <- intersection closest_to target_point;
			current_path <- compute_path(graph: road_network, target: target);
			if (current_path = nil) {
				intersection tmp_intersection <- (intersection-tested_targets) closest_to self;
				location <- tmp_intersection.location;
				tested_targets<<tmp_intersection;
				if intersection-tested_targets = []{
					to_be_killed <- true;
				}
			} 
			else {
				is_visible <- true;
			}
		}
		
	}																																							//<-gama-issue14-may08	
	reflex move when: current_path != nil and final_target != nil and not dead(self){
		
		try{
			do drive;
			if final_target = nil{
				to_be_killed <- true;
			}
			else if (final_target != nil) {
				if real_speed < 5 #km / #h {
					counter_stucked <- counter_stucked + 1;
					if (counter_stucked mod threshold_stucked = 0) {
						proba_use_linked_road <- min([1.0, proba_use_linked_road + 0.1]);
					}
		
				} else {
					counter_stucked <- 0;
					proba_use_linked_road <- 0.0;
				}
			}			
		}
	}
	reflex kill_agent when: to_be_killed{					//gama-issue14-may08->
		do die;
	}																				//<-gama-issue14-may08
	
	aspect default {
		if is_visible{
			if (display3D) {
			point loc <- calcul_loc();
			draw rectangle(1,vehicle_length) + triangle(1) rotate: heading + 90 depth: 1 color: color at: loc;
			if (breakdown) {
				draw circle(1) at: loc color: #red;
			}
			}else {
				rgb my_color <- breakdown?#red:rgb(255,255,255,0.7);
				draw circle(vehicle_length*0.5) color:my_color;// rotate: heading + 90;
			}
		}		
	}

	point calcul_loc {
		if (current_road = nil) {
			return location;
		} else {
			float val <- (road(current_road).num_lanes - current_lane) + 0.5;
			val <- on_linked_road ? -val : val;
			if (val = 0) {
				return location;
			} else {
				return (location + {cos(heading + 90) * val, sin(heading + 90) * val});
			}

		}

	} }