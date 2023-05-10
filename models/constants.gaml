/**
* Name: constants
*  
* Author: Gamaliel Palomo, Juan Alvarez, Arnaud Grignard
* Tags: 
*/


model constants

global{
	string main_shp_path <- "../includes/shp/";
	string main_csv_path <- "../includes/csv/";
		
	string entry_points_filename <- "../includes/shp/environment/entry_points.shp";
	string dcu_limits_filename <- "../includes/shp/environment/scenario_limits.shp";
	string dcu_transport_filename <- "environment/paradas_transporte_publico_dcu.shp";
	string dcu_massive_transport_filename <- "environment/estaciones_transporte_masivo_dcu.shp";
	string dcu_cycling_way_filename <- "../includes/shp/environment/ciclovias_dcu.shp";
	string satellite_file <- "../includes/img/ccu_satellite.png";
	string green_areas_file <- "/environment/green_areas.shp";
	
	//Files related to interventions
	string intervention_areas_filename  <- "environment/intervention_areas.shp";	
	string economic_activities_filename <- "scenario1/economic_activities.shp";
	string projects_csv_filename <- "/projects.csv";
	string projects_shp_filename <- "/scenario2/projects.shp";
	string allowed_activities_by_use_filename <- "/EQUIV_SCIAN_PP.csv";
	string day_activities_csv_filename <- "/day_activities.csv";
	string night_activities_csv_filename <- "/night_activities.csv";
	string knowledge_activities_csv_filename <- "/knowledge_activities.csv";
	string interaction_places_csv_filename <- "/interaction_places.csv";
	string third_places_csv_filename <- "/third_places.csv";
	
	//List of files that are used to simulate the people flows in the case of cultural events
	string events_roads_filename <- main_shp_path + "events/roads.shp";
	string events_entry_points_filename <- main_shp_path + "events/entry_points.shp";
	string events_locations_filename <- main_shp_path + "events/event_location.shp";
	
	//map<string,float> mobility_speed <- ["pedestrian"::1.4,"bicycle"::3.0,"bus"::4.1,"car"::5.0];
	map<string,rgb> use_type_color <- ["Espacios verdes abiertos y recreativos"::#seagreen,
																	"Alojamiento temporal"::#yellow,
																	"Habitacional"::#yellow,
																	"Habitacional, Servicios a la industria y al comercio"::#yellow,
																	"Comercial y de servicios"::rgb (228, 58, 63,255),
																	"Comercial"::rgb (228, 58, 63,255),
																	"Servicios"::rgb (228, 58, 63,255),
																	"Mixto"::rgb (159, 0, 0,255),
																	"Industrial"::#slateblue,
																	"Servicios a la industria y al comercio"::#slateblue,
																	"Equipamiento"::#dodgerblue,
																	"Recreación y descanso"::#limegreen,
																	"Instalaciones especiales e infraestructura"::#gray,
																	"Vialidad"::#gray
																	];
		map<string,rgb> use_type_color_zonification <- ["Espacio verde"::#seagreen,
																	"Alojamiento temporal"::rgb (255, 0, 255,255),
																	"Habitacional"::#yellow,
																	"Habitacional, Servicios a la industria y al comercio"::#yellow,
																	"Comercial y de servicios"::rgb (228, 58, 63,255),
																	"Comercial"::rgb (228, 58, 63,255),
																	"Servicios"::rgb (228, 58, 63,255),
																	"Mixto"::rgb (159, 0, 0,255),
																	"Comercial"::#slateblue,
																	"Industrial"::#slateblue,
																	"Equipamiento"::#dodgerblue,
																	"Recreación y descanso"::#limegreen,
																	"Instalaciones especiales e infraestructura"::#gray,
																	"Vialidad"::#gray];
	
	list denue_activites <- [
		"611122",
		"611121",
		"611312",
		"611311"
	];
	list universities <- ["611311","611312"];
	//Students mobility data
	map<string,float> student_mobility_percentages<-[
		"Caminando"::0.4008,
		"Bicicleta"::0.0162,
		"Metro, tren ligero o tren suburbano"::0.0024,
		"Trolebus"::0.0,
		"Metrobús"::0.0028,
		"Camión, autobús, combi o colectivo"::0.2331,
		"Transporte escolar"::0.0334,
		"Taxi convencional"::0.0007,
		"Taxi de aplicación"::0.0017,
		"Motocicleta"::0.0116,
		"Automóvil propio"::0.2953,
		"Otro"::0.002
	];
	map<string,float> worker_mobility_percentages<-[
		"Caminando"::0.13001,
		"Bicicleta"::0.0424,
		"Metro, tren ligero o tren suburbano"::0.0021,
		"Trolebus"::0.0,
		"Metrobús"::0.0039,
		"Camión, autobús, combi o colectivo"::0.3527,
		"Transporte escolar"::0.0355,
		"Taxi convencional"::0.0028,
		"Taxi de aplicación"::0.0038,
		"Motocicleta"::0.034,
		"Automóvil propio"::0.3826,
		"Otro"::0.00101
	];
	map<string,rgb> mobility_colors<-[
		"Caminando"::#yellow,
		"Bicicleta"::#green,
		"Metro, tren ligero o tren suburbano"::#slateblue,
		"Trolebus"::#mediumorchid,
		"Metrobús"::#blue,
		"Camión, autobús, combi o colectivo"::rgb (188, 131, 44,255),
		"Transporte escolar"::rgb (239, 95, 236,255),
		"Transporte de personal"::rgb (239, 95, 236,255),
		"Taxi convencional"::rgb (51, 172, 154,255),
		"Taxi de aplicación"::#cornflowerblue,
		"Motocicleta"::rgb (241, 176, 160,255),
		"Automóvil propio"::#red,
		"Otro"::#white
	];
	map<string,float> mobility_speed<-[
		"Caminando"::4.5,
		"Bicicleta"::12.5,
		"Metro, tren ligero o tren suburbano"::9.72222,
		"Trolebus"::7.77778,
		"Metrobús"::7.77778,
		"Camión, autobús, combi o colectivo"::17.4,
		"Transporte escolar"::8.4,
		"Transporte de personal"::8.4,
		"Taxi convencional"::10.9,
		"Taxi de aplicación"::10.9,
		"Motocicleta"::32.5,
		"Automóvil propio"::16.3,
		"Otro"::5.0
	];
	map<string,float> energy_requirement_map<-["Económica"::769.41,"Media"::3130.58,"Residencial"::3730.58];
	map<string,float> waste_generation_map<-["Económica"::0.755,"Media"::1.005,"Residencial"::1.106];
	map<string,float> water_requirement_map<-["Económica"::251.0,"Media"::535.0,"Residencial"::689.0];
	list<float> roads_km <- [87.954,93.88];
	float students_percentage <- 0.28;
	float workers_percentage <- 0.45;
	float ccu_area_ha <- 155.277;
	float dcu_area_ha <- 456.0;
	float ccu_area_km2 <- ccu_area_ha * 0.01;
	
	list<float>s1_values <- [0.29971232822840527,0.5662388000764331,0.3371347549024506,0.35730413291554636,0.14918276063874233,0.7830046562585573,0.47887457615284046,0.5226646066080343,0.45011252813203295,0.7316829207301826,0.02852153502011456,0.8670975549722401,0.5226646066080343,0.5768042549058664];
	list<float>s2_values <- [0.5814758130665304,0.8578181534493942,0.6204619000160776,0.353634698584762,0.1548924007974432,0.7808334394586737,0.37493608930814676,0.4092216070348485,0.3003003003003003,0.48815482148815487,0.02719682584560077,0.8978271599920978,0.4092216070348485,0.7934099217735945];
	list<float>cs_values;
	
	
	//Edge values
	
	float max_diversity <- 6.0;
	float max_transport_accessibility <- 1.0;
	float max_hab_emp_ratio <- 20.0;
	float max_density <- 350.0;
	float max_energy_requirement <- 7384.94;
	float max_water_requirement <- 886.0;
	float max_waste_generation <- 1.217;
	float max_km_per_person <- 20.0;
	float max_km_per_km2 <- 1.0;
	float max_green_area_per_person <- 40.0;
	int max_schools_near <- 4;
	int max_hospitals_near <-4;
	int max_culture_near <- 10;
	
	int min_culture_equipment 		<- 3;
	int min_education_equipment 	<- 4;
	int min_health_equipment 		<- 3;
	int min_sports_equipment 		<- 1;
	
	float distance2health 		<- 200#m;
	float distance2culture 		<- 200#m;
	float distance2education 	<- 200#m;
	
	float mean_family_size <- 2.7;
	
	
	//New version
	
	int spread_value_factor <- 10;
	float spread_factor <- 0.5;
	map<string,int> education_distances <- ["Preescolar"::500,"Primaria"::750,"Secundaria"::1000,"Bachillerato"::5000,"Licenciatura"::10000];
	map<string,int> culture_distances <- ["Auditorio Estatal"::10000,"Auditorio Municipal"::2340,"Biblioteca Municipal"::1500,"Casa de la Cultura"::10000,"Escuela Integral de Artes"::10000,"Museo Local"::10000,"Teatro"::10000,"Biblioteca pública estatal"::10000];
	map<string,int> health_distances <- ["Centro de Sallud Urbano (SSA)"::1000,"Clínica Hospitall"::10000,"Consultorio Privadol"::1000,"Hospital Privado"::10000,"Hospital General"::10000,"Hospital General (SSA)l"::10000,"Laboratorio"::10000,"Unidad de Medicina Familiar"::5000,"Unidad de Medicina Familiar (IMSS)"::5000];
	map<string,int> sports_distances <- ["Equipamiento deportivo"::1000];
	
	int delay_before_export_data 			<- 100;
	int delay_before_update_heatmap 	<- 50;
	
	int nb_people_prop <- 5;
	
	
	//Variables related to heatmap
	map<string,list<string>> heatmap_names <- ["facilities"::["health","culture","education","sports"],"population/housing"::["population_density","mobility"],"activities_density"::["day_density","night_density","knowledge_density","interaction_density"],"activities_diversity"::["day_diversity","night_diversity","knowledge_diversity"]];
	
}