// Gmsh project created on Mon Feb 24 15:19:05 2020
SetFactory("OpenCASCADE");

Include "Project_data.geo"; 

Coherence;

// Num_litz = 10; //Cas test

//********************* Geometrical calculations *********************//

// Dimension of the new conductor
alpha = 2*Pi/Num_litz; 
If (Num_litz == 1)
	Rayon  = 0;
Else
	If (Flag_Insulation )
		Rayon  = (2*(Rc+d_cond))/(Sqrt((1-Cos(alpha))*(1-Cos(alpha))+(Sin(alpha))*(Sin(alpha))))+Insulation; // Imaginary circle radius
	Else
		Rayon  = (2*(Rc+d_cond))/(Sqrt((1-Cos(alpha))*(1-Cos(alpha))+(Sin(alpha))*(Sin(alpha)))); // Imaginary circle radius		
	EndIf
EndIf
// Previous way of computing the new conductor dimension... I think the computation of the perimeter is a simplified approached
// where the perimeter of circle is approximated by a finite sum of straight line... The other version does not make this assumption
// If (Flag_Insulation )
	// perimeter = Num_litz*(2*(Rc+Insulation)+4*mili);  //4*mili corresponds to a value
	// Rayon     = perimeter/(2*Pi); 
// Else
	// perimeter = Num_litz*(2*Rc+4*mili);  //4*mili corresponds to a value (interwinding)
	// Rayon     = perimeter/(2*Pi); 	
// EndIf


// Domain size 
If (Flag_Insulation)
	param = Rayon + (Rc + Insulation) + R_airbox; //The real value
	// param = 3*Rayon+2*Insulation;
Else
	// param = 3*Rayon;
	param = Rayon + (Rc) + R_airbox; //The real value
EndIf

// Mesh size
lc_Conductor  = Rc / 50;
lc_Insulation = lc_Conductor;
lc_Air        = (2*param)/50;

//********************* Creation of the geometry *********************//
//Non-insulated conductor
cp = newp ;
Point(cp)   = {Rayon        , 0    , 0 ,lc_Conductor} ;
Point(cp+1) = {Rayon + Rc, 0    , 0 ,lc_Conductor} ;
Point(cp+2) = {Rayon        , Rc, 0 ,lc_Conductor} ;
Point(cp+3) = {Rayon - Rc, 0    , 0 ,lc_Conductor} ;
Point(cp+4) = {Rayon        ,-Rc, 0 ,lc_Conductor} ;

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
	Point(cp+1) = {Rayon + Rc + Insulation, 0                 , 0 ,lc_Insulation} ;
	Point(cp+2) = {Rayon                     , Rc + Insulation, 0 ,lc_Insulation} ;
	Point(cp+3) = {Rayon - Rc - Insulation, 0                 , 0 ,lc_Insulation} ;
	Point(cp+4) = {Rayon                     ,-Rc - Insulation, 0 ,lc_Insulation} ;

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

// Circulare Arrangement of the insulated conductor:
	For i In {1:Num_litz-1}
		out_i[] = Rotate{{0,0,1},{0,0,0},2*Pi/Num_litz}{Duplicata{Surface{c_i};}}; //c_i = conductor with insulation
 		c_i  = out_i[0]                  ;
		Surf_c_w_i() += out_i[0]         ;  		
	EndFor

	d() = BooleanDifference{Surface{c_ab};Delete;}{Surface{Surf_c_w_i(0):Surf_c_w_i(#Surf_c_w_i()-1)};};
	For i In {0:#Surf_c_w_i()-1}
		e() += BooleanDifference{Surface{Surf_c_w_i(i)};Delete;}{Surface{Surf_c(i)};Delete;};
	EndFor
 	x()  = Boundary{Surface{d(0)};};
	x() -= Boundary{Surface{e(0):e(#e()-1)};};
Else 
	d()  = BooleanDifference{Surface{c_ab};Delete;}{Surface{Surf_c()};Delete;};
	x()  = Boundary{Surface{d(0)};};
	x() -= b_c();
EndIf

//********************* Definition of the physicals *********************//
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
