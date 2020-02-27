// Gmsh project created on Mon Feb 24 15:19:05 2020
SetFactory("OpenCASCADE");

Include "Project_data.geo" ; 

Coherence;

Num_litz = 10; //Cas test

//Internal radius (that of the air)
If (Flag_Insulation )
	perimeter = Num_litz*(2*(Delta+Insulation)+4*mili);  //4*mili corresponds to a value
	Rayon     = perimeter/(2*Pi); 
Else
	perimeter = Num_litz*(2*Delta+4*mili);  //4*mili corresponds to a value (interwinding)
	Rayon     = perimeter/(2*Pi); 	
EndIf

//Non-insulated conductor
cp = newp ;
Point(cp)   = {Rayon        , 0    , 0 ,lc_Conductor} ;
Point(cp+1) = {Rayon + Delta, 0    , 0 ,lc_Conductor} ;
Point(cp+2) = {Rayon        , Delta, 0 ,lc_Conductor} ;
Point(cp+3) = {Rayon - Delta, 0    , 0 ,lc_Conductor} ;
Point(cp+4) = {Rayon        ,-Delta, 0 ,lc_Conductor} ;

cl  = newl ;
Circle(cl)   = {cp+1, cp, cp+2} ;
Circle(cl+1) = {cp+2, cp, cp+3} ;
Circle(cl+2) = {cp+3, cp, cp+4} ;
Circle(cl+3) = {cp+4, cp, cp+1} ;

For j In {0:3}
	skin_conductor() += cl+j;
EndFor

cll = newll; 
Line Loop(cll) = {skin_conductor()} ;

cs  = news;
Plane Surface(cs) = {cll};
b_c() += {skin_conductor()} ;
Surf_c() += cs;

//Air box
If (Flag_Insulation )
//param = Rayon + 2*(Delta + Insulation) + R_airbox; //The real value
	param = 3*Rayon+2*Insulation;
Else
	param = 3*Rayon;
//param = Rayon + 2*(Delta) + R_airbox; //The real value

EndIf

cp = newp;
 	Point(cp)   = { param, param, 0 , lc_Air} ;
	Point(cp+1) = {-param, param, 0 , lc_Air} ;
	Point(cp+2) = {-param,-param, 0 , lc_Air} ;
	Point(cp+3) = { param,-param, 0 , lc_Air} ;

cl = newl;
	Line(cl)   = {cp  , cp+1} ;
	Line(cl+1) = {cp+1, cp+2} ;
	Line(cl+2) = {cp+2, cp+3} ;
	Line(cl+3) = {cp+3, cp  } ;

For j In {0:3}
	skin_airbox() += cl+j;
EndFor

abll = newll; 
Line Loop(abll) = {skin_airbox()};

//Defining the Surface of The AirBox:
c_ab  = news; Plane Surface(c_ab) = {abll};

//Circular arrangement of the naked conductors:
For i In {1:Num_litz-1}
	out_c[]  = Rotate{{0,0,1},{0,0,0},2*Pi/Num_litz}{Duplicata{Surface{cs};}};
 	cs       = out_c[0] ;
 	Surf_c()+= out_c[0] ;//Surface copper without insulation
 	b_c()   += Boundary{Surface{cs};}  ;
EndFor

//Insulation
If (Flag_Insulation)
	cp = newp;
	Point(cp)   = {Rayon                     , 0                 , 0 ,lc_Conductor} ;
	Point(cp+1) = {Rayon + Delta + Insulation, 0                 , 0 ,lc_Insulation} ;
	Point(cp+2) = {Rayon                     , Delta + Insulation, 0 ,lc_Insulation} ;
	Point(cp+3) = {Rayon - Delta - Insulation, 0                 , 0 ,lc_Insulation} ;
	Point(cp+4) = {Rayon                     ,-Delta - Insulation, 0 ,lc_Insulation} ;

	cl = newl;
	Circle(cl)   = {cp+1, cp, cp+2} ;
	Circle(cl+1) = {cp+2, cp, cp+3} ;
	Circle(cl+2) = {cp+3, cp, cp+4} ;
	Circle(cl+3) = {cp+4, cp, cp+1} ;

	For j In {0:3}
		skin_Insulation() += cl+j; 
	EndFor

	ill = newll;        //Insulation Line loop
	Line Loop(ill)    = {skin_Insulation()} ;
	b_i() += {skin_Insulation};
	c_i    = news;

	Plane Surface(c_i) = {ill};
	Surf_c_w_i() += {c_i}     ; 

//Circulare Arrangement of the insulated conductor:
	For i In {1:Num_litz-1}
		out_i[] = Rotate{{0,0,1},{0,0,0},2*Pi/Num_litz}{Duplicata{Surface{c_i};}}; //c_i = conductor with insulation
 		c_i  = out_i[0]                  ;
		Surf_c_w_i() += out_i[0]         ;  		
	EndFor

	d() = BooleanDifference{Surface{c_ab};Delete;}{Surface{Surf_c_w_i(0):Surf_c_w_i(#Surf_c_w_i()-1)};};
	For i In {0:#Surf_c_w_i()-1}
		e() += BooleanDifference{Surface{Surf_c_w_i(i)};Delete;}{Surface{Surf_c(i)};Delete;};
	EndFor
	//I will need x() for the physicals:
 	x()  = Boundary{Surface{d(0)};};
	x() -= Boundary{Surface{e(0):e(#e()-1)};};
Else 
	d()  = BooleanDifference{Surface{c_ab};Delete;}{Surface{Surf_c()};Delete;};
	x()  = Boundary{Surface{d(0)};};
	x() -= b_c();
EndIf

//Defining the physicals
	//Airbox
Physical Surface("AirbBox with holes", SURF_AIRBOX) = {d(0)};
Physical Line("Airbox Skin", SKIN_AIRBOX) ={x()} ;//Fucking air box ! 
	//Conductors
Physical Line("Skin of conductors",SKIN_CONDUCTORS) = {b_c()};
//	//Insulations
If (Flag_Insulation)
	Physical Surface("Surface of Insulations",SURF_INSULATIONS)={e()};
EndIf

//Hell fucking yes!!!
//Remarque: pour le cas Flag_Insulation = 1 on doit réarranger les conducteurs de manière à ne pas avoir de l'air au centre