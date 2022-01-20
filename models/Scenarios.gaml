/**
* Name: cityscope
* Based on the internal empty template. 
* Author: gamaa
* Tags: 
*/


model cityscope
import "constants.gaml"

global{
	
	file limits_shp <- file(dcu_limits_filename);
	file blocks_shp <- file(dcu_blocks_filename);
	file blocks_residencial_shp <- file(dcu_blocks_residencial_filename);
	file roads_shp <- file(dcu_roads_filename);
	file denue_shp <- file(denue_filename);
	file ppdu_shp <- file(ppdu_blocks_filemane);
	file entry_points_shp <- file(entry_points_filename);
	file transport_shp <- file(dcu_transport);
	file massive_shp <- file(dcu_massive_transport_filename);
	file cycling_shp <- file(dcu_cycling_way_filename);
	file students_shp <- file(dcu_students_filename);
	file zonification_shp <- file(zonification_ccu_filename);
	geometry shape <- envelope(limits_shp);
	graph road_network;
	list<denue> schools;
	map<string,int> mobility_count;
	map<string,path> agent_routes;
	bool show_accessibility_by_agent parameter:"Accesibilidad a medios de transporte por persona" <- false;
	bool show_use parameter:"Uso de suelo" <- false;
	bool show_zonification parameter:"Mostrar zonificación CCU" <- false;
	bool show_zonification_use parameter:"Mostrar uso de suelo zonificación" <- false;
	//bool use_percentage parameter:"Población a partir de porcentaje" <- false;
	float transport_accessibility_distance parameter:"Distancia mínima a parada" <- 500.0 min:1.0 max:1000.0 ;
	string case_study <- "students";
	list<people> new_people;
	init{
		step <-5#seconds;
		starting_date <- date("2022-1-18 06:00:00");
		create roads from:roads_shp;
		road_network <- as_edge_graph(roads);
		create dcu from: limits_shp;
		create transport_station from:transport_shp;
		create massive_transport from:massive_shp with:[type::string(read("Sistema"))];
		create cycling_way from:cycling_shp;
		create denue from:denue_shp with:[id::string(read("id")),activity_code::string(read("codigo_act"))];
		create ppdu_blocks from:ppdu_shp with:[fid::string(read("fid")),use::string(read("Descripci2"))];
		schools <- denue where(each.activity_code in universities);
		loop i from:0 to:length(mobility_colors.keys)-1{
			add mobility_colors.keys[i]::0 to:mobility_count;
		}
		create blocks_residencial from:blocks_residencial_shp with:[id::string(read("CVEGEO"))];
		create blocks from:blocks_shp with:[id::string(read("CVEGEO")),nb_people::int(read("POBTOT")),nb_students::int(read("P15A17A"))+int(read("P18A24A"))];
		ask schools{
			ask blocks{
				path the_path <- path_between(road_network,self,myself);
				/*loop while: the_path = nil{
					point a <- any_location_in(first(roads closest_to(self)));
					point b <-  any_location_in(first(roads closest_to(myself)));
					the_path <- path_between(road_network,a,b);
				}*/
				add string(myself.id)::the_path to:route_to;
			}
		}
		create people from:students_shp with:[my_school_id::string(read("school")),home_block_id::string(read("home_block")),mobility_mode::string(read("mobility_m"))]{
			activity_type <- "student";
			home <- location;
			home_block <- first(blocks where(each.id=home_block_id));
			my_school <- first(denue where(each.id = my_school_id));
			
			if my_school = nil {
				write "nil school";
			}
			mobility_count[mobility_mode] <- mobility_count[mobility_mode] + 1;
		}

		float sum <- 0.0;
		ask people{
			transport_station the_station <- transport_station closest_to self;
			float distance1 <- the_station distance_to self;
			sum <- sum + distance1;
			massive_transport closest_brt <- massive_transport where(each.type="BRT (Bus Rapid Transit)") closest_to self;
			float distance2 <- closest_brt distance_to self;
			massive_transport closest_light_train <- massive_transport where(each.type="Tren Eléctrico") closest_to self;
			float distance3 <- closest_light_train distance_to self;
			cycling_way closest_cycling_way <- cycling_way closest_to self;
			float distance4 <- closest_cycling_way distance_to self;
			if distance1 < 300{
				transport_accessibilty_count <- transport_accessibilty_count + 1;
			} 
			if distance2 < 500{
				transport_accessibilty_count <- transport_accessibilty_count + 1;
			}
			if distance3 < 800{
				transport_accessibilty_count <- transport_accessibilty_count + 1;
			}
			if distance4 < 300{
				transport_accessibilty_count <- transport_accessibilty_count + 1;
			}
			
		}
		create zonification_blocks from:zonification_shp with:[id::string(read("id")),use::string(read("Uso")),parking::int(read("CAJ_ESTAC"))]{
			if id = "NULL"{do die;}
			if parking = nil {do die;}
			
			create people number:parking/5{
				activity_type <- "student";//one_of(["student","worker"]);
				location <- any_location_in(myself);
				home <- location;
				home_block <- first(blocks closest_to(self));
				mobility_mode <- "Automóvil propio";
				if activity_type = "student"{
					my_school <- one_of(schools);
				}
				else if activity_type = "worker"{
					my_work <- one_of(denue);
				}
				mobility_count[mobility_mode] <- mobility_count[mobility_mode] + 1;
				add self to:new_people;
				new_one <- true;
			}
		}
		
		//write "Indice de accesibilidad autobus: "+length(people where(each.transport_accessibilty_count>=3))/length(people);
		
		
		create entry_points from:entry_points_shp;
		
		/*create people number:1000{
			location <- any_location_in(one_of(entry_points));
			objective <-one_of(denue).location;
			mobility_mode <- one_of(["pedestrian","bicycle","car","bus"]);
		}*/
		
		//write "Connected components: "+string(length(connected_components_of(road_network)));
		blocks_shp <- [];
		ppdu_shp <- [];
		roads_shp <- [];
		denue_shp <- [];
		entry_points_shp <- [];
		transport_shp <- [];
		blocks_residencial_shp <- [];
		students_shp <- [];
	}
	
}
/*grid heatmap width:30 height:30{
	float traffic_value <- 0.0;
	reflex update_traffic when:flip(0.5) and every(30#seconds){
		traffic_value <- length(people at_distance(200#m) where(each.mobility_mode="Automóvil propio"))/50;
	}
	aspect traffic{
		draw shape color:rgb(200,20,20,traffic_value);
	}
}*/
species cycling_way{
	
}
species blocks_residencial{
	string id;
}
species zonification_blocks{
	string id;
	string use;
	int parking;
	aspect default{
		if show_zonification_use{
			draw shape color:use_type_color_zonification[use];
		}
	}
}
species transport_station{
	image_file my_icon <- image_file("../includes/img/bus.png") ;
	
	aspect default{
		draw my_icon size:40;
		//draw square(30) color:#red;
	}
}
species massive_transport{
	string type;
}
species entry_points{
	aspect default{
		draw circle(10) color:#red;
	}
}
species denue{
	string id;
	string activity_code;
	aspect default{
		draw triangle(10) color:rgb (44, 177, 201,0.5);
	}
}
species people skills:[moving] parallel:true{
	point home;
	string home_block_id;
	blocks home_block;
	string activity_type;
	denue my_school;
	string my_school_id;
	denue my_work;
	map<date,string> agenda_day;
	//Mobility
	string mobility_mode;
	int transport_accessibilty_count <- 0;
	string current_activity;
	int point_index;
	list<point>  my_route;
	bool new_one <- false;
	reflex update_agenda when: empty(agenda_day) or (every(#day) and (!new_one or (new_one and show_zonification))){
		agenda_day <- [];
		point the_activity_location <- activity_type="student"?my_school.location:my_work.location;
		denue the_activity <- activity_type="student"?my_school:my_work;
		int activity_time <- rnd(2,12);
		int init_hour <- rnd(6,12);
		int init_minute <- rnd(0,59);
		date activity_date <- date(current_date.year,current_date.month,current_date.day,init_hour,init_minute,0);
		agenda_day <+ (activity_date::"activity");
		activity_date <- activity_date + activity_time#hours;
		init_minute <- rnd(0,59);
		activity_date <- activity_date + init_minute#minutes;
		agenda_day <+ (activity_date::"home");
	}
	reflex update_activity when:not empty(agenda_day) and (after(agenda_day.keys[0])) and (!new_one or (new_one and show_zonification)){
		current_activity <-agenda_day.values[0];
		if current_activity = "activity"{
			my_route <- home_block.route_to[my_school.id].shape.points;
		}
		else{
			my_route <- home_block.route_to[my_school.id].shape.points;
			list<point> reverse;
			loop i from:0 to:length(my_route)-1{
				add my_route[length(my_route)-1-i] to: reverse;
			}
			my_route <- reverse;
		}
		point_index <- 0;
		agenda_day>>first(agenda_day);
	}
	reflex movement when:point_index<length(my_route) and (!new_one or (new_one and show_zonification)){
		do goto target:my_route[point_index] speed:mobility_speed[mobility_mode]#km/#h;
		if location = my_route[point_index]{
			point_index<- point_index + 1;
		}
	}
	
	string select_mobility_mode{
		float sum <- 0.0;
		float selection <- rnd(100)/100;
		//loop mode over:activity_type="student"?student_mobility_percentages.keys:student_mobility_percentages.keys{
		loop mode over:activity_type="student"?student_mobility_percentages.keys:worker_mobility_percentages.keys{
			if selection < student_mobility_percentages[mode] + sum{
				return mode;
			}
			sum <- sum + student_mobility_percentages[mode];
		}
		//write name + ": i will select a random mobility type";
		return one_of(student_mobility_percentages.keys);
	}
	aspect mobility_accessibility{
		if show_accessibility_by_agent{
			float tmp <- transport_accessibilty_count /4;
			rgb my_color <- rgb((1-tmp)*255,tmp*255,100);
			if (new_one and show_zonification) or !new_one{
				draw circle(5) color:my_color;
			}
		}
		else{
			if (new_one and show_zonification) or !new_one{
				draw circle(5) color:mobility_colors[mobility_mode];
			}
		}
		
	}
	aspect default{
		draw circle(5) color:mobility_colors[mobility_mode];
	}
}

species dcu{
	aspect default{
		draw shape color:#blue empty:true;
	} 
}
species blocks{
	string id;
	map<string,path> route_to;
	int nb_people;
	int nb_students;
	int nb_workers;
	
	float accessibility_index;
	
	rgb my_color <- rgb(0,0,0,0.3);
	reflex update_accessibility{
		list<transport_station> near_stations <- transport_station at_distance(transport_accessibility_distance);
		accessibility_index <- 0.0;
		if not empty(near_stations){
			transport_station closest <- near_stations closest_to centroid(self);
			accessibility_index <- 1-((closest distance_to self)/transport_accessibility_distance);
		}		
	}
	
	aspect default{
		if not show_use{
			draw shape color:my_color border:#white;
		}
	}
	aspect only_border{
		draw shape empty:true border:#white;
	}
	aspect transport_access{
		draw shape color:rgb (48, 216, 78,accessibility_index);
	}
}
species ppdu_blocks{
	string fid;
	string use;
	aspect use_type{
		if show_use{
			rgb my_color <- use in use_type_color.keys?use_type_color[use]:rgb(0,0,0,0);
			my_color <- rgb(my_color.red,my_color.green,my_color.blue,0.6);
			draw shape color:my_color border:#gray;
		}
		
	}
}
species roads{
	aspect default{
		draw shape color:#gray;
	}
}
experiment Estudiantes type:gui{
	parameter "case study" var:case_study <- "students";
	output{
		display Estudiantes type:opengl background:#black draw_env:false refresh:length(people)>2000?every(1#cycle):every(2#cycle){
			//species dcu aspect:default refresh:every(1#hour);
			//species denue aspect:default;
			
			//species blocks aspect:transport_access;
			species ppdu_blocks aspect:use_type;
			species zonification_blocks aspect:default;
			species transport_station aspect:default;
			//species roads aspect:default;
			species people aspect:mobility_accessibility trace:1.0;
			//species heatmap aspect:traffic;
						overlay size: { 5 #px, 50 #px } {
				draw "áéíóúabcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ.:0123456789([])" at: {0#px,0#px} color:rgb(0,0,0,0) font: font("Arial", 15, #plain);
				draw "áéíóúabcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ.:0123456789" at: {0#px,0#px} color:rgb(0,0,0,0) font: font("Arial", 25,#bold);
				draw "áéíóúabcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ.:0123456789" at: {0#px,0#px} color:rgb(0,0,0,0) font: font("Arial", 20,#bold);
				draw "Uso de suelo" color:#white at:{50,420} font: font("Arial", 20,#bold);
				loop i from:0 to:length(use_type_color.keys)-1{
					draw square(30) color:use_type_color.values[i] at:{50,520+100*i};
					draw use_type_color.keys[i]  color:#white at:{100,530+100*i} font: font("Arial", 15, #plain);
				}
				draw string(current_date) at:{30#px,30#px} color:#white font: font("Arial", 25,#bold);
				draw "Population: "+length(people) at:{30#px,50#px} color:#white font: font("Arial", 20,#bold);
				draw "Medio de transporte" color:#white at:{50,2000} font: font("Arial", 20,#bold);
				loop i from:0 to:length(mobility_colors.keys)-1{
					draw circle(30) color:mobility_colors.values[i] at:{50,2100+100*i} ;
					draw mobility_colors.keys[i] + " ("+mobility_count[mobility_colors.keys[i]] +")" at:{100,2130+100*i} font: font("Arial", 15, #plain) color:#white;
					//
				}
			}
		}
	}
}
experiment Trabajadores type:gui{
	parameter "case study" var:case_study <- "workers";
	output{
		display Trabajadores type:opengl background:#black draw_env:false refresh:length(people)>2000?every(1#cycle):every(2#cycle){
			//species dcu aspect:default refresh:every(1#hour);
			//species denue aspect:default;
			species blocks aspect:default;
			species ppdu_blocks aspect:use_type;
			species roads aspect:default;
			species people aspect:default;
						overlay size: { 5 #px, 50 #px } {
				draw "áéíóúabcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ.:0123456789([])" at: {0#px,0#px} color:rgb(0,0,0,0) font: font("Arial", 15, #plain);
				draw "áéíóúabcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ.:0123456789" at: {0#px,0#px} color:rgb(0,0,0,0) font: font("Arial", 25,#bold);
				draw "áéíóúabcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ.:0123456789" at: {0#px,0#px} color:rgb(0,0,0,0) font: font("Arial", 20,#bold);
				draw "Uso de suelo" color:#white at:{50,420} font: font("Arial", 20,#bold);
				loop i from:0 to:length(use_type_color.keys)-1{
					draw square(30) color:use_type_color.values[i] at:{50,520+100*i};
					draw use_type_color.keys[i]  color:#white at:{100,530+100*i} font: font("Arial", 15, #plain);
				}
				draw string(current_date) at:{30#px,30#px} color:#white font: font("Arial", 25,#bold);
				draw "Population: "+length(people) at:{30#px,50#px} color:#white font: font("Arial", 20,#bold);
				draw "Medio de transporte" color:#white at:{50,2000} font: font("Arial", 20,#bold);
				loop i from:0 to:length(mobility_colors.keys)-1{
					draw circle(30) color:mobility_colors.values[i] at:{50,2100+100*i} ;
					draw mobility_colors.keys[i] + " ("+mobility_count[mobility_colors.keys[i]] +")" at:{100,2130+100*i} font: font("Arial", 15, #plain) color:#white;
					//
				}
			}
		}
	}
}