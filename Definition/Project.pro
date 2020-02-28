// Remarque: j'ai enlevé le 'include project_data' parce qu'il y avait un probleme de syntaxe lorsque je runais le code...
// Du coup certain paramètres sont redéfini en dur ici comme le Flag_Insulation... J'essaie de régler le problème de syntaxe, 
// j'ai fait ça comme ça en attendant pour qu'on puisse déjà avancer dans les simulations :) 

//Include "Project_data.geo" ;
Flag_Insulation = 0;

Group {
  Skin_Airbox = Region[500000]; //Ground :) 
  Surf_Airbox = Region[600000];

  Skin_conductors = Region[700000];

  Vol_Ele = Region[ {Surf_Airbox} ];
  Sur_Neu_Ele = Region[ {} ];

  If (Flag_Insulation)
    Surf_Insulations = Region[900000];
    Vol_Ele += Region[{Surf_Insulations}];
  EndIf
}

Function {
   eps0 = 8.854187818e-12; 
   Ins_epsr = 3.5;
    epsilon[Surf_Airbox]        = 1. * eps0;
  If (Flag_Insulation )
    epsilon[Surf_Insulations] = Ins_epsr * eps0;  
  EndIf
}

Constraint {
  { Name Dirichlet_Ele; Type Assign;
    Case {
      { Region Skin_Airbox    ; Value 0.     ; }
      { Region Skin_conductors; Value 550000; }
    }
  }
}

Group{
  Dom_Hgrad_v_Ele =  Region[ {Vol_Ele, Sur_Neu_Ele} ];
}

FunctionSpace {
  { Name Hgrad_v_Ele; Type Form0;
    BasisFunction {
      { Name sn; NameOfCoef vn; Function BF_Node;
        Support Dom_Hgrad_v_Ele; Entity NodesOf[ All ]; }
    }
    Constraint {
      { NameOfCoef vn; EntityType NodesOf; NameOfConstraint Dirichlet_Ele; }
    }
  }
}

Include "../Libraries/Library.pro"; 

Formulation {
  { Name Electrostatics_v; Type FemEquation;
    Quantity {
      { Name v; Type Local; NameOfSpace Hgrad_v_Ele; }
    }
    Equation {
      Integral { [ epsilon[] * Dof{d v} , {d v} ];
	    In Vol_Ele; Jacobian Vol; Integration Int; }
    }
  }
}

Resolution {
  { Name EleSta_v;
    System {
      { Name Sys_Ele; NameOfFormulation Electrostatics_v; }
    }
    Operation {
      Generate[Sys_Ele]; Solve[Sys_Ele]; SaveSolution[Sys_Ele];
    }
  }
}

PostProcessing {
  { Name EleSta_v; NameOfFormulation Electrostatics_v;
    Quantity {
      { Name v; Value {
          Term { [ {v} ]; In Dom_Hgrad_v_Ele; Jacobian Vol; }
        }
      }
      { Name e; Value {
          Term { [ -{d v} ]; In Dom_Hgrad_v_Ele; Jacobian Vol; }
        }
      }
      { Name d; Value {
          Term { [ -epsilon[] * {d v} ]; In Dom_Hgrad_v_Ele; Jacobian Vol; }
        }
      }
    }
  }
}

e = 1.e-7; // tolerance to ensure that the cut is inside the simulation domain
h = 2.e-3; // vertical position of the cut

PostOperation {
  { Name Map; NameOfPostProcessing EleSta_v;
     Operation {
       Print [ v, OnElementsOf Vol_Ele, File "Homework1_V.pos" ];
       Print [ e, OnElementsOf Vol_Ele, File "Homework1_E.pos" ];
	   //Print [ e, OnLine {{e,5,0}{15-e,5,0}}{500}, File "Cut_e.pos" ];
     }
  }
  { Name Cut; NameOfPostProcessing EleSta_v;
		// same cut as above, with more points and exported in raw text format
		Operation {
			Print [ e, OnLine {{e,5,0}{15-e,5,0}} {15000}, Format TimeTable, File "d_cond_study\5cond\d50mm.txt" ];
		}
  }
}

