/**
* Name: Trafficmodel
* Model to test the graph generation and the driving skill for agents.
 
* Author: gamaa
* Tags: 
*/


model Trafficmodel
import "constants.gaml"

global{
	file events_roads_shp <- file("../includes/shp/events/roads_test.shp");
	file events_entry_points_shp <- file(events_entry_points_filename);
	file events_location_points_shp <- file(events_locations_filename);
	file events_nodes_shp <- file("../includes/shp/events/nodes.shp");
	/*file events_roads_shp <- file("../includes/shp/events/roads_mit.shp");
	file events_entry_points_shp <- file("../includes/shp/events/entry_points_mit.shp");
	file events_location_points_shp <- file("../includes/shp/events/event_location_mit.shp");
	file events_nodes_shp <- file("../includes/shp/events/nodes_mit.shp");*/
	
	graph event_roads_network;
	map event_roads_weight;
	geometry shape <- envelope(events_roads_shp);
	init{
		create roads from:events_roads_shp;
		create intersection from:events_nodes_shp;
		event_roads_weight <- roads as_map (each::each.shape.perimeter);
		event_roads_network <- as_driving_graph(roads,intersection); 
		//event_roads_network <- roads as_intersection_graph 0.1 with_weights event_roads_weight;
		//event_roads_network <- as_edge_graph(roads);
		create entry_point from:events_entry_points_shp with:[rate::int(read("porcentaje"))];
		create event_location from:events_location_points_shp with:[capacity::int(read("avg_asiste"))];
	}
	//This reflex is to produce people flows for the mobility simulation
	reflex generate_people_flows when:sum(event_location collect(each.capacity - each.current_people))>0{
		ask entry_point{
			 
			if flip(self.rate/100){
				event_location tmp_location <- first(event_location where((each.capacity-each.current_people)>0));
				create car with:[my_event::tmp_location, location::self.location];
				ask tmp_location{current_people <- current_people - 1;}
			}
			
		}
	}
	
}
species intersection skills:[skill_road_node]{
	aspect default{
		draw circle(2) wireframe:false color:rgb(255,255,255,0.5) border:#red;
	}
}
species car skills:[advanced_driving,moving]{
	bool valid <- false;
	float vehicle_length <- 5.0;
	float max_speed <- 30.0;
	bool violating_one_way <- true;
	list<int> allowed_lines <- [0,1];
	
	event_location my_event;
	path the_path;
	intersection target;
	reflex build_path when:final_target =nil{
		using topology(world){	
			intersection int_tmp <- first(intersection at_distance(2000) where(each.roads_out!=[] closest_to self));
			location <- int_tmp.location;
			target <- intersection closest_to first(event_location);
			current_path <- compute_path(graph: event_roads_network, target: target);
			if current_path != nil {valid <- true;}
		}
	}
	reflex validate{
		//if not valid{do die;}
	}
	/*reflex build_path when:current_path = nil{
		the_path <- path_between(event_roads_network,location,target);
		write the_path;
	}*/
	
	reflex drive when:current_path != nil and final_target != nil{
		//do drive_random graph:event_roads_network;
		//do goto target:target on:event_roads_network speed:0.05;
		do drive;
	}
	aspect default{
		draw circle(2.5#m) color:current_lane=0?rgb (248, 236, 7,0.5):rgb (234, 34, 34,0.5);
		draw circle(0.5) color:current_lane=0?rgb (248, 236, 7,0.5):rgb (234, 34, 34,0.5);
		draw triangle(20) at:target.location color:#yellow;
		if current_path != nil{
			loop i from:0 to:length(list(current_path.shape.points))-2{
				draw line(list(current_path.shape.points)[i],list(current_path.shape.points)[i+1]) color:#red;
			}
		}
	}
}
//Entry points
species entry_point{
	float rate <- 0.0;
	aspect default{
		draw square(20) wireframe:true border:#white width:2.0;
	}
}
species event_location{
	int capacity;
	int current_people <- 0;
	aspect default{
		draw circle(10) color:#blue;
	}
	aspect event_paths{
		loop element over:event_roads_network.vertices{
				draw circle(5) color:#white at:geometry(element).location wireframe:true border:#white;
		}
		loop element over:event_roads_network.edges{
			graph_edge tmp <- graph_edge(element);
			draw tmp color:#red ;
		}
	}
}
species roads skills:[skill_road]{
	aspect default{
		draw shape color:#gray width:2.0 end_arrow:4;
	}
}

experiment test type:gui{
	output{
		display main type:opengl axes:false background:#black{
			species roads aspect:default refresh:false;
			species car aspect:default;
			species event_location aspect:default;
			//species event_location aspect:event_paths;
			species entry_point aspect:default refresh:false;
			species intersection aspect:default refresh:false;
		}
	}
}
