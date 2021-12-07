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
	file roads_shp <- file(dcu_roads_filename);
	file denue_shp <- file(denue_filename);
	file ppdu_shp <- file(ppdu_blocks_filemane);
	file entry_points_shp <- file(entry_points_filename);
	geometry shape <- envelope(limits_shp);
	graph road_network;
	list<denue> schools;
	map<string,int> mobility_count;
	
	bool show_use parameter:"Uso de suelo" <- false;
	bool use_percentage parameter:"Población a partir de porcentaje" <- false;
	string case_study <- "students";
	init{
		step <-2#seconds;
		starting_date <- date("2021-12-6 04:00:00");
		create dcu from: limits_shp;
		create denue from:denue_shp with:[activity_code::string(read("codigo_act"))];
		create ppdu_blocks from:ppdu_shp with:[fid::string(read("fid")),use::string(read("Descripci2"))];
		schools <- denue where(each.activity_code in universities);
		loop i from:0 to:length(mobility_colors.keys)-1{
			add mobility_colors.keys[i]::0 to:mobility_count;
		}
		create blocks from:blocks_shp with:[nb_people::int(read("POBTOT")),nb_students::int(read("P15A17A"))+int(read("P18A24A"))]{
			if case_study = "students"{
				create people number:use_percentage?int(nb_people*0.28):nb_students{
					activity_type <- "student";
					home  <- any_location_in(myself);
					my_school <- one_of(schools);
				}
			}
			else if case_study = "workers"{
				create people number:int(nb_people*workers_percentage){
					activity_type <- "worker";
					home  <- any_location_in(myself);
					my_work <- one_of(denue);
				}				
			}
			
		}
		ask people{
			do init_location;
		}
		create entry_points from:entry_points_shp;
		create roads from:roads_shp;
		/*create people number:1000{
			location <- any_location_in(one_of(entry_points));
			objective <-one_of(denue).location;
			mobility_mode <- one_of(["pedestrian","bicycle","car","bus"]);
		}*/
		road_network <- as_edge_graph(roads);
		blocks_shp <- [];
		ppdu_shp <- [];
		roads_shp <- [];
		denue_shp <- [];
		entry_points_shp <- [];
		
	}
}
species entry_points{
	aspect default{
		draw circle(10) color:#red;
	}
}
species denue{
	string activity_code;
	aspect default{
		draw triangle(10) color:rgb (44, 177, 201,0.5);
	}
}
species people skills:[moving] parallel:50{
	point home;
	string activity_type;
	point objective;
	denue my_school;
	denue my_work;
	map<date,point> agenda_day;
	//Mobility
	string mobility_mode;
	
	action init_location{
		location <- home;
		mobility_mode <- select_mobility_mode();
		mobility_count[mobility_mode] <- mobility_count[mobility_mode] + 1;
	}
	action main_behavior{
		do wander;
	}
	reflex update_agenda when: every(#day){
		agenda_day <- [];
		point the_activity_location <- activity_type="student"?my_school.location:my_work.location;
		float activity_time <- gauss(8,2);
		float init_hour <- gauss(8,1);
		float init_minute <- gauss(30,2);
		date activity_date <- date(current_date.year,current_date.month,current_date.day,init_hour,init_minute,0);
		agenda_day <+ (activity_date::the_activity_location);
		activity_date <- activity_date + activity_time#hours;
		init_minute <- gauss(30,2);
		activity_date <- activity_date + init_minute#minutes;
		agenda_day <+ (activity_date::home);
	}
	reflex update_activity when:not empty(agenda_day) and (after(agenda_day.keys[0])){
		objective <- agenda_day.values[0];
		objective <- {objective.x+rnd(10)-rnd(10),objective.y+rnd(10)-rnd(10)};
		agenda_day>>first(agenda_day);
	}
	reflex movement when:location!=objective{
		do goto target:objective speed:mobility_speed[mobility_mode] on:road_network;
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
		write name + ": i will select a random mobility type";
		return one_of(student_mobility_percentages.keys);
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
	int nb_people;
	int nb_students;
	int nb_workers;
	
	rgb my_color <- rgb(0,0,0,0.3);
	aspect default{
		if not show_use{
			draw shape color:my_color border:#white;
		}
	}
}
species ppdu_blocks{
	string fid;
	string use;
	aspect use_type{
		rgb my_color <- use in use_type_color.keys?use_type_color[use]:rgb(0,0,0,0);
		my_color <- rgb(my_color.red,my_color.green,my_color.blue,0.6);
		if show_use{
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
		display Estudiantes type:opengl background:#black draw_env:false refresh:length(people)>2000?every(5#cycle):every(10#cycle){
			//species dcu aspect:default refresh:every(1#hour);
			//species denue aspect:default;
			
			species blocks aspect:default;
			species ppdu_blocks aspect:use_type;
			//species roads aspect:default;
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
experiment Trabajadores type:gui{
	parameter "case study" var:case_study <- "workers";
	output{
		display Trabajadores type:opengl background:#black draw_env:false refresh:length(people)>2000?every(5#cycle):every(10#cycle){
			//species dcu aspect:default refresh:every(1#hour);
			//species denue aspect:default;
			species blocks aspect:default;
			species ppdu_blocks aspect:use_type;
			//species roads aspect:default;
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