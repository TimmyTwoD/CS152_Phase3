    /* cs152-miniL phase2 */
%{
 #include <stdio.h>
 #include <stdlib.h>
 #include <string>
 #include <iostream>
 #include <set>
 #include <sstream>
 #include <cstring>

int labelNum = 0;
 int tempVar = 0;

 using namespace std;
 void yyerror(const char *msg);
 extern int yylex();
 extern int currLine; 
 extern int currPos; 
 FILE * yyfileIn;

 string tempStr();
 string label();
%}

%union{
  /* put your types here */
  int dval;
  char* str;

    struct A {
        bool isArray;
        char* name;
        char* code;
    } express;

    struct B {
        char* code;
    } statem;
}

%type <express> function declarations declaration identifiers ident bool_exp relation_and_exp relation_exp
%type <express> comp expression expressions multiplicative_expression term vars var
%type <statem> statements statement


%error-verbose
%start prog_start
%token FUNCTION SEMICOLON BEGIN_PARAMS END_PARAMS BEGIN_LOCALS END_LOCALS BEGIN_BODY END_BODY INTEGER ARRAY ENUM OF IF THEN ENDIF ELSE FOR WHILE DO BEGINLOOP ENDLOOP CONTINUE READ WRITE AND OR NOT TRUE FALSE RETURN COLON COMMA 
%right ASSIGN ":="
%left OR "|"
%left AND "&"
%right NOT "!"
%left LT "<" LTE "<=" GT ">" GTE ">=" EQ "=" NEQ "!="
%left ADD "+" SUB "-"
%left MULT "*" DIV "/" MOD "%"
%left L_SQUARE_BRACKET "[" R_SQUARE_BRACKET "]"
%left L_PAREN "(" R_PAREN ")"
%token <dval> NUMBER
%token <str> IDENT
/* %start program */

%% 

    /* write your rules here */
    prog_start:
        functions {}
    ;

    functions:
        %empty {}
        |function functions {}
    ;

    function:
        FUNCTION ident SEMICOLON BEGIN_PARAMS declarations END_PARAMS BEGIN_LOCALS declarations END_LOCALS BEGIN_BODY statements END_BODY {
            stringstream code;
            code << "func " << $2.name << "\n" << $5.code << $8.code << $11.code << "endfunc\n\n";
            cout << code.str();
        }
    ;

    declarations:
        declaration SEMICOLON declarations {
            stringstream code;
            code << $1.code << $3.code;
            $$.code = strdup(code.str().c_str());
            $$.name = strdup("");
        }
        | %empty {
            $$.name = strdup("");
            $$.code = strdup("");
        }
    ;

    declaration:
        identifiers COLON INTEGER {
            int right = 0;
            int left = 0;
            stringstream temp;
            string replace($1.name);
            bool ex = false;
            while(!ex) {
                right = replace.find("/", left);
                temp << ". ";
                if (right == string::npos) {
                    string ident = replace.substr(left, right);
                    temp << ident;
                    ex = true;
                } else {
                    string ident = replace.substr(left, right-left);
                    temp << ident;
                    left = right + 1;
                }
                temp << "\n";
            }
            string temp1 = temp.str();
            $$.code = strdup(temp1.c_str());
            $$.name = strdup("");
        }
        |identifiers COLON ENUM L_PAREN identifiers R_PAREN {
            /* dont know */
            
        }
        |identifiers COLON ARRAY L_SQUARE_BRACKET NUMBER R_SQUARE_BRACKET OF INTEGER {
            stringstream temp;
            temp << ".[] " << $1.name;
            temp <<", "<< to_string($5) << "\n";
            string temp1 = temp.str();
            $$.code = strdup(temp1.c_str());
            $$.name = strdup("");
        }
    ;

    identifiers:
        ident {
            $$.code = strdup("");
            $$.name = strdup($1.name);
        }
        |ident COMMA identifiers {
            stringstream temp;
            temp << $1.name << "/" << $3.name;
            string temp2 = temp.str();
            $$.code = strdup("");
            $$.name = strdup(temp2.c_str());
        }
    ;

    ident:
        IDENT {
            $$.code = strdup("");
            $$.name = strdup($1);
        }
    ;

 
    statements:
        statement SEMICOLON statements {
            stringstream code;
            code << $1.code << $3.code;
            $$.code = strdup(code.str().c_str());
        }
        | statement SEMICOLON{
            $$.code = strdup($1.code);
        }
    ;

    statement:
        var ASSIGN expression {
            stringstream code;
            code << $1.code << $3.code;

            if($1.isArray){
                code << "[]= ";
            }else if($3.isArray){
                code << "= ";
            }else{
                code << "= ";
            }
            code << $1.name << ", " << $3.name << "\n";
            $$.code = strdup(code.str().c_str());
        }
        |IF bool_exp THEN statements ENDIF {
            string label1 = label();
            string label2 = label();
            stringstream code;
            code << $2.code; 
            code << "?:= " << label1 << ", " << $2.name << "\n";
            code << ":= " << label2 << "\n";
            code << ": " << label1 << "\n";
            code << $4.code;
            code << ": " << label2 << "\n";
            $$.code = strdup(code.str().c_str());
        }
        |IF bool_exp THEN statements ELSE statements ENDIF {
            string label1 = label();
            string label2 = label();
            stringstream code;
            code << $2.code; 
            code << "?:= " << label1 << ", " << $2.name << "\n";
            code << $6.code;
            code << ":= " << label2 << "\n";
            code << ": " << label1 << "\n";
            code << $4.code;
            code << ": " << label2 << "\n";
            $$.code = strdup(code.str().c_str());
        }
        |WHILE bool_exp BEGINLOOP statements ENDLOOP {
            stringstream code;
            string label1 = label();
            string label2 = label();
            string label3 = label();
            string largerCode = $4.code;
            size_t temp = largerCode.find("cont");
            while(temp != string::npos){
                largerCode.replace(temp, 4, ":= " + label1);
                temp = largerCode.find("cont");
            }
            code << ": " << label1 << "\n";
            code << $2.code;
            code << "?:= " << label2 << ", ";
            code << $2.name << "\n";
            code << ":= " << label3 << "\n";
            code << ": " << label2 << "\n";
            code << largerCode;
            code << ":= " << label1 << "\n";
            code << ": " << label3 << "\n";
            $$.code = strdup(code.str().c_str());
        }
        |DO BEGINLOOP statements ENDLOOP WHILE bool_exp {
            stringstream code;
            string label1 = label();
            string label2 = label();
            string largerCode = $3.code;
            size_t temp = largerCode.find("cont");
            while(temp != string::npos){
                largerCode.replace(temp, 4, ":= " + label2);
                temp = largerCode.find("cont");
            }
            code << ": " << label1 << "\n" << largerCode;
            code << ": " << label2 << "\n";
            code << $6.code;
            code << "?:= " << label1 << ", ";
            code << $6.name << "\n";
            $$.code = strdup(code.str().c_str());
        }
        |READ vars {
            string code; 
            code.append($2.code);
            size_t temp = code.find("/", 0);
            while(temp != string::npos){
                code.replace(temp, 1, "<");
                temp = code.find("/", temp);
            }
            $$.code = strdup(code.c_str());
        }
        |WRITE vars {
            string code;
            code.append($2.code);
            size_t temp = code.find("/", 0);
            while(temp != string::npos){
                code.replace(temp, 1, ">");
                temp = code.find("/", temp);
            }
            $$.code = strdup(code.c_str());
        }
        |CONTINUE {
            $$.code = strdup("cont\n");
        }
        |RETURN expression {
            stringstream code;
            code << $2.code << "ret " << $2.name << "\n";
            $$.code = strdup(code.str().c_str());
        }
    ;

    bool_exp:
        relation_and_exp {
            $$.name = strdup($1.name);
            $$.code = strdup($1.code);
        }
        |relation_and_exp OR relation_and_exp {
            stringstream temp;
            string temp1 = tempStr();
            temp << $1.code << $3.code;
            temp << ". " << temp1 << "\n";
            temp << "|| "<< temp1 << ", ";
            temp << $1.name << ", " << $3.name << "\n";
            $$.name = strdup(temp1.c_str());
            $$.code = strdup(temp.str().c_str());
        }
    ;

    relation_and_exp:
        relation_exp {
            $$.name = strdup($1.name);
            $$.code = strdup($1.code);
        }
        |relation_and_exp AND relation_exp {
            stringstream temp;
            string temp1 = tempStr();
            temp << $1.code << $3.code;
            temp << ". " << temp1 << "\n";
            temp << "&& " << temp1 << ", ";
            temp << $1.name << ", " << "$3.name" << "\n";
            string temp2 = temp.str();
            $$.name = strdup(temp1.c_str());
            $$.code = strdup(temp2.c_str());
        }
    ;

    relation_exp:
        expression comp expression {
            stringstream temp;
            string temp1 = tempStr();
            temp << $1.code << $3.code;
            temp << ". " << temp1 << "\n" << $2.name << temp1 << ", " << $1.name << ", " << $3.name << "\n";
            string temp2 = temp.str();
            $$.name = strdup(temp1.c_str());
            $$.code = strdup(temp2.c_str());
        }
        |TRUE {
            string temp;
            temp.append("1");
            $$.name = strdup(temp.c_str());
            $$.code = strdup("");
            
        }
        |FALSE {
            string temp;
            temp.append("0");
            $$.name = strdup(temp.c_str());
            $$.code = strdup("");
        }
        |L_PAREN bool_exp R_PAREN {
            $$.name = strdup($2.name);
            $$.code = strdup($2.code);
        }

        |NOT expression comp expression {
            stringstream temp;
            string temp1 = tempStr();
            temp << $2.code << $4.code;
            temp << "! " << temp1 << ", ";
            temp << ". " << temp1 << "\n" << $3.name << temp1 << ", " << $2.name << ", " << $4.name << "\n";
            string temp2 = temp.str();
            $$.name = strdup(temp1.c_str());
            $$.code = strdup(temp2.c_str());
        }
        |NOT TRUE {
            string temp;
            temp.append("0");
            $$.name = strdup(temp.c_str());
            $$.code = strdup("");
        }
        |NOT FALSE {
            string temp;
            temp.append("1");
            $$.name = strdup(temp.c_str());
            $$.code = strdup("");
        }
        |NOT L_PAREN bool_exp R_PAREN {
            stringstream temp;
            temp << $3.code << "! " << $3.name << ", " << $3.name;
            string temp2 = temp.str();
            $$.name = strdup($3.name);
            $$.code = strdup(temp2.c_str());
        }
    ;

    comp:
        EQ {
            $$.code = strdup("");
            $$.name = strdup("== ");
        }
        |NEQ {
            $$.code = strdup("");
            $$.name = strdup("!= ");
        }
        |LT {
            $$.code = strdup("");
            $$.name = strdup("< ");
        }
        |GT {
            $$.code = strdup("");
            $$.name = strdup("> ");
        }
        |LTE {
            $$.code = strdup("");
            $$.name = strdup("<= ");
        }
        |GTE {
            $$.code = strdup("");
            $$.name = strdup(">= ");
        }
    ;

    expression:
        multiplicative_expression {
            $$.code = strdup($1.code);
            $$.name = strdup($1.name);
        }
        |expression SUB multiplicative_expression {
            stringstream temp;
            string temp1 = tempStr();
            temp << $1.code << $3.code;
            temp << ". " << temp1 << "\n";
            temp << "- " << temp1 << ", ";
            temp << $1.name << ", " << $3.name << "\n";
            string temp2 = temp.str();
            $$.code = strdup(temp2.c_str());
            $$.name = strdup(temp1.c_str());
        }
        |expression ADD multiplicative_expression {
            stringstream temp;
            string temp1 = tempStr();
            temp << $1.code << $3.code;
            temp << ". " << temp1 << "\n";
            temp << "+ " << temp1 << ", ";
            temp << $1.name << ", " << $3.name << "\n";
            string temp2 = temp.str();
            $$.code = strdup(temp2.c_str());
            $$.name = strdup(temp1.c_str());
        }
    ;

    expressions:
        %empty{
            $$.name = strdup("");
            $$.code = strdup("");
        }
        |expression COMMA expressions {
            stringstream temp;
            temp << $1.code << "param " << $1.name << "\n";
            temp << $3.code;
            string temp2 = temp.str();
            $$.code = strdup(temp2.c_str());
            $$.name = strdup("");
        } 
        |expression {
            stringstream temp;
            temp << $1.code << "param " << $1.name << "\n";
            string temp2 = temp.str();
            $$.code = strdup(temp2.c_str());
            $$.name = strdup("");
        }

        /* need to check expressions */
    ;

    multiplicative_expression:
        term {
            $$.code = strdup($1.code);
            $$.name = strdup($1.name);
        }
        |term DIV term {
            stringstream temp;
            string temp1 = tempStr();
            temp << $1.code << $3.code << ". " << temp1 << "\n";
            temp << "/ " << temp1 << ", " << $1.name << ", " << $3.name << "\n";
            string temp2 = temp.str();
            $$.code = strdup(temp2.c_str());
            $$.name = strdup(temp1.c_str());
        }
        |term MULT term {
            stringstream temp;
            string temp1 = tempStr();
            temp << $1.code << $3.code << ". " << temp1 << "\n";
            temp << "* " << temp1 << ", " << $1.name << ", " << $3.name << "\n";
            string temp2 = temp.str();
            $$.code = strdup(temp2.c_str());
            $$.name = strdup(temp1.c_str());
        } 
        |term MOD term {
            stringstream temp;
            string temp1 = tempStr();
            temp << $1.code << $3.code << ". " << temp1 << "\n";
            temp << "% " << temp1 << ", " << $1.name << ", " << $3.name << "\n";
            string temp2 = temp.str();
            $$.code = strdup(temp2.c_str());
            $$.name = strdup(temp1.c_str());
        }
    ;

    term:
        var {
            stringstream temp;
            string temp1 = tempStr();
            temp << $1.code;
            if ($1.isArray) {
                temp << $1.code << ". " << temp1 << "\n";
                temp << "=[] " << temp1 << ", " << $1.name << "\n";
            } else {
                temp << ". " << temp1 << "\n";
                temp << "= " << temp1 << ", " << $1.name << "\n";
                temp << $1.code;
            }
            string temp2 = temp.str();
            $$.code = strdup(temp2.c_str());
            $$.name = strdup(temp1.c_str());
            
        }
        |NUMBER {
            stringstream temp;
            string temp1 = tempStr();
            temp << ". " << temp1 << "\n";
            temp << "= " << temp1 << ", " << to_string($1) << "\n";
            string temp2 = temp.str();
            $$.code = strdup(temp2.c_str());
            $$.name = strdup(temp1.c_str());

        }
        |L_PAREN expression R_PAREN {
            $$.code = strdup($2.code);
            $$.name = strdup($2.name);
        }
        |SUB var {
            stringstream temp;
            string temp1 = tempStr();
            if ($2.isArray) {
                temp << $2.code << ". " << temp1 << "\n";
                temp << "=[] " << temp1 << ", " << $2.name << "\n";
            } else {
                temp << ". " << temp1 << "\n";
                temp << "= " << temp1 << ", " << $2.name << "\n";
                temp << $2.code;
            }
            temp << "* " << temp1 << ", " << temp1 << "-1\n";
            string temp2 = temp.str();
            $$.code = strdup(temp2.c_str());
            $$.name = strdup(temp1.c_str());
        }
        |SUB NUMBER {
            stringstream temp;
            string temp1 = tempStr();
            temp << ". " << temp1 << "\n";
            temp << "= " << temp1 << ", -" << to_string($2) << "\n";
            string temp2 = temp.str();
            $$.code = strdup(temp2.c_str());
            $$.name = strdup(temp1.c_str());
        }
        |SUB L_PAREN expression R_PAREN {
            stringstream temp;
            temp << $3.code << "* " << $3.name << ", -1\n";
            string temp1 = temp.str();
            $$.code = strdup(temp1.c_str());
            $$.name = strdup($3.name);
        }
        |ident L_PAREN expressions R_PAREN {
            stringstream temp;
            string temp1 = tempStr();
            temp << $3.code;
            temp << ". " << temp1 << "\ncall ";
            temp << $1.name;
            temp << ", " << temp1 << "\n";
            string temp2 = temp.str();
            $$.code = strdup(temp2.c_str());
            $$.name = strdup(temp1.c_str());
        }
    ;

    vars:
        var COMMA vars {
            stringstream temp;
            temp << $1.code;
            if ($1.isArray) {
                temp << ".[]/ ";
            } else {
                temp << "./ ";
            }
            temp << $1.name << "\n" << $3.code;
            string temp1 = temp.str();
            $$.code = strdup(temp1.c_str());
            $$.name = strdup("");
        }
        |var {
            stringstream temp;
            temp << $1.code;
            if ($1.isArray) {
                temp << ".[]/ ";
            } else {
                temp << "./ ";
            }
            temp << $1.name << "\n";
            string temp1 = temp.str();
            $$.code = strdup(temp1.c_str());
            $$.name = strdup("");
        }
    ;

    var:
        ident {
            $$.code = strdup("");
            $$.name = strdup($1.name);
            $$.isArray = false;
        }
        |ident L_SQUARE_BRACKET expression R_SQUARE_BRACKET {
            stringstream temp;

            temp << $1.name << ", " << $3.name;
            string temp1 = temp.str();
            $$.code = strdup($3.code);
            $$.name = strdup(temp1.c_str());
            $$.isArray = true;
        }
    ;

    
  

%% 


string tempStr() {
    string s = "__temp__" + to_string(tempVar);
    tempVar++;
    return s;
}

string label(){
    string temp = "__label__" + to_string(labelNum);
    labelNum++;
    return temp;
}

int main(int argc, char **argv) {
    if(argc >= 2){
      yyfileIn = fopen(argv[1], "r");
      if(yyfileIn == NULL){
         yyfileIn = stdin;
      }
    }
    else{
      yyfileIn = stdin;
    }
    yyparse();
    return 0;
}

void yyerror(const char *msg) {
    printf("Error: On line %d, column %d: %s \n", currLine, currPos, msg);
    
}