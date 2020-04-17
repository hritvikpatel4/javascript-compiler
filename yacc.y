%{
    #include<stdio.h>
    #include<stdlib.h>
    #include<string.h>
    #include<ctype.h>

//------------Symbol table---------------------
    struct symTab{
    char *id_name;
    int line_no;
    int scope;
    char val[10];
    char *type;
    }symbolTable[200];

    int line=1;
    int count=0;
    int scope=0;

    void display();
    int search(char*);
    void installID(char*, char*, char*);

//----------------AST---------------------------
    typedef struct Abstract_syntax_tree {
        char *name;
        struct Abstract_syntax_tree *left;
        struct Abstract_syntax_tree *right;
        char res[100];
        char reg_name[10];
    }node; 

    node* buildTree(char *,node *,node *);
    void printTree(node *);

//-----------------ICG---------------------------
    struct quad
	{
		char op[5];
		char arg1[10];
		char arg2[10];
		char result[10];
        int scope;
		char block[10];
        int pos;
	}Quad[30];

    int number;
	int Index = 0;
	int rIndex=0; 
    char block[10];
    int bIndex=0;
	void add_quadruple(char *op,char *arg1,char *arg2,char *result,int option);
	
	struct stack 
	{
		char label[10][10];
		int top;
	}stk;
	void push(char *label);	
	void pop();
	char* get_top();
	void eprint(struct quad);

//---------------Misc--------------------------
    char *name,*value, *type;
    int flag=1;
    int flag1=1;
    int getTeq(char*, char*, char*, char*);
    void yyerror();

%}


//-------------------------------------------------------Token and type declarations---------------------------------------------------------------
%union {
    struct Abstract_syntax_tree *node;
    char sval[100];
}

%token<sval> tk_for tk_do tk_while tk_var tk_true tk_false tk_null
%token<sval> tk_obrace tk_cbrace tk_opar tk_cpar
%token<sval> tk_add tk_sub tk_mul tk_div tk_mod
%token<sval> tk_l tk_g tk_le tk_ge
%token<sval> tk_not tk_eq tk_neq tk_deq tk_teq
%token<sval> tk_tern tk_choice tk_and tk_or tk_dand tk_dor 
%token<sval> tk_identifier tk_inumber tk_fnumber 
%token<sval> tk_sc
%token<sval> tk_str

%type<node> S C COND LOOPS LOOPBODY LOOPC ASSIGN_EXPR EXP ADDSUB TERM FACTOR LIT ternary_statement TERNARY_EXPR statement A 
%type<sval> RELOP

%left tk_add tk_sub tk_mul tk_div 
%left tk_l tk_g tk_le tk_ge
%left tk_neq tk_deq tk_teq
%left tk_tern tk_choice tk_and tk_or tk_dand tk_dor 
%left tk_opar tk_obrace
%right tk_cpar tk_cbrace
%right tk_not tk_eq


//--------------------------------------------------------------Grammar--------------------------------------------------------------------------
%%
S
    : C 
    ;

C
    : C statement tk_sc {
                            printTree($2);
                            printf("\n");
                            printf("--------------------------------------------------------------------------\n");
                        }
    | C LOOPS {
                printTree($2);
                printf("\n");
                printf("--------------------------------------------------------------------------\n");
                }
    | statement tk_sc {
                        printTree($1);
                        printf("\n");
                        printf("--------------------------------------------------------------------------\n");
                    }
    | LOOPS {
                printTree($1);
                printf("\n");
                printf("--------------------------------------------------------------------------\n");
            }

    | error tk_sc
    ;

LOOPS
    : tk_do{sprintf(block,"do_while%d",bIndex++);push(block);} LOOPBODY tk_while tk_opar{scope+=1;} COND tk_cpar tk_sc {$$=buildTree("DO_WHILE",$3,$7);pop();scope-=1;}
    | tk_for tk_opar ASSIGN_EXPR{scope+=1;sprintf(block,"for%d",bIndex++);push(block);} tk_sc COND tk_sc statement tk_cpar{scope-=1;} LOOPBODY {$$=buildTree("FOR",$6,$11);pop();}
    ;

COND
    : LIT RELOP LIT {$$=buildTree($2,$1,$3); add_quadruple($2,$1->reg_name,$3->reg_name,"",0);}
    | LIT {$$=buildTree("!=",$1,"0");add_quadruple("!=",$1->reg_name,"0","",0);}
    | un_boolop LIT {$$=buildTree("==",$2,"0"); add_quadruple("==",$2->reg_name,"0","",0);}
    ;

LOOPBODY
    : tk_obrace{scope+=1;} LOOPC tk_cbrace {$$=$3; scope-=1;}
    | tk_sc {$$=NULL;}
    | statement tk_sc {$$=$1;}
    ;

LOOPC
    : LOOPC statement tk_sc {$$=buildTree("SEQ",$1,$2);}
    | statement tk_sc {$$=$1;}
    ;

statement
    : ASSIGN_EXPR {$$ = $1;}
    | EXP {$$=$1;}
    | TERNARY_EXPR {$$=$1;}
    ;

ASSIGN_EXPR
    : LIT tk_eq{flag1=0;} EXP {$$=buildTree("=",$1,$4); 
                    if(!flag1){
                        add_quadruple("=",$4->res,"",$1->reg_name,0); 
                        if(scope==0){installID($1->reg_name,$4->res,type);} }
                    else{
                        add_quadruple("=",$4->reg_name,"",$1->reg_name,0); 
                         }
                    flag=1; flag1=1;}
    | TYPE LIT A { $$=buildTree("=",$2,$3); 
                    if($3!=NULL){
                        if(!flag1){
                            add_quadruple("=",$3->res,"",$2->reg_name,0);
                            if(scope==0){installID($2->reg_name,$3->res,type);} }
                        else{
                            add_quadruple("=",$3->reg_name,"",$2->reg_name,0); 
                            } }
                    flag=1; flag1=1;}
    ;

A
    :
    tk_eq{flag1=0;} EXP {$$=$3;}
    | {$$=NULL;}
    ;

EXP
    : ADDSUB {$$=$1;}
    | EXP tk_l ADDSUB {$$=buildTree("<",$1,$3); 
                        if(flag1){add_quadruple("<",$1->reg_name,$3->reg_name,$$->reg_name,1);}
                        sprintf($$->res,"%d",(atoi($1->res)<atoi($3->res)));}
    | EXP tk_g ADDSUB {$$=buildTree(">",$1,$3); 
                        if(flag1){add_quadruple(">",$1->reg_name,$3->reg_name,$$->reg_name,1); }
                        sprintf($$->res,"%d",(atoi($1->res)>atoi($3->res)));}
    | EXP tk_le ADDSUB {$$=buildTree("<=",$1,$3); 
                        if(flag1){add_quadruple("<=",$1->reg_name,$3->reg_name,$$->reg_name,1); }
                        sprintf($$->res,"%d",(atoi($1->res)<=atoi($3->res)));}
    | EXP tk_ge ADDSUB {$$=buildTree(">=",$1,$3); 
                        if(flag1){add_quadruple(">=",$1->reg_name,$3->reg_name,$$->reg_name,1); }
                        sprintf($$->res,"%d",(atoi($1->res)>=atoi($3->res)));}
    | EXP tk_neq ADDSUB {$$=buildTree("!=",$1,$3); 
                        if(flag1){add_quadruple("!=",$1->reg_name,$3->reg_name,$$->reg_name,1); }
                        sprintf($$->res,"%d",(atoi($1->res)!=atoi($3->res)));}
    | EXP tk_deq ADDSUB {$$=buildTree("==",$1,$3); 
                        if(flag1){add_quadruple("==",$1->reg_name,$3->reg_name,$$->reg_name,1); }
                        sprintf($$->res,"%d",(atoi($1->res)==atoi($3->res)));}
    | EXP tk_teq ADDSUB {$$=buildTree("===",$1,$3); 
                        if(flag1){add_quadruple("===",$1->reg_name,$3->reg_name,$$->reg_name,1);} 
                        sprintf($$->res,"%d",getTeq($1->res,$3->res,$1->reg_name,$3->reg_name));}
    | EXP tk_and ADDSUB {$$=buildTree("&",$1,$3); 
                        if(flag1){add_quadruple("&",$1->reg_name,$3->reg_name,$$->reg_name,1); }
                        sprintf($$->res,"%d",(atoi($1->res)&atoi($3->res)));}
    | EXP tk_or ADDSUB {$$=buildTree("|",$1,$3); 
                        if(flag1){add_quadruple("|",$1->reg_name,$3->reg_name,$$->reg_name,1); }
                        sprintf($$->res,"%d",(atoi($1->res)|atoi($3->res)));}
    ;
	  
ADDSUB
    : TERM {$$=$1;}
    | EXP tk_add TERM {$$=buildTree("+",$1,$3); 
                        if(flag1){add_quadruple("+",$1->reg_name,$3->reg_name,$$->reg_name,1); }
                        sprintf($$->res,"%d",(atoi($1->res)+atoi($3->res)));}
    | EXP tk_sub TERM {$$=buildTree("-",$1,$3); 
                        if(flag1){add_quadruple("-",$1->reg_name,$3->reg_name,$$->reg_name,1); }
                        sprintf($$->res,"%d",(atoi($1->res)-atoi($3->res)));}
    ;

TERM
    : FACTOR {$$=$1;}
    | TERM tk_mul FACTOR {$$=buildTree("*",$1,$3); 
                            if(flag1){add_quadruple("*",$1->reg_name,$3->reg_name,$$->reg_name,1); }
                            sprintf($$->res,"%d",(atoi($1->res)*atoi($3->res)));}
    | TERM tk_div FACTOR {$$=buildTree("/",$1,$3); 
                            if(flag1){add_quadruple("/",$1->reg_name,$3->reg_name,$$->reg_name,1); }
                            sprintf($$->res,"%d",(atoi($1->res)/atoi($3->res)));}
    | TERM tk_mod FACTOR {$$=buildTree("%",$1,$3); 
                            if(flag1){add_quadruple("%",$1->reg_name,$3->reg_name,$$->reg_name,1); }
                            sprintf($$->res,"%d",(atoi($1->res)%atoi($3->res)));}
    ;
      
FACTOR
    : LIT {$$=$1;}
    | tk_opar EXP tk_cpar {$$ = $2;}
    ;
      
TERNARY_EXPR
    : tk_opar COND{sprintf(block,"tern%d",bIndex++);strcpy(Quad[Index-1].block,block);push(block);} tk_cpar tk_tern ternary_statement {$$=buildTree("?",$2,$6);pop();}
    ;

ternary_statement
    : ASSIGN_EXPR tk_choice ASSIGN_EXPR {$$ = buildTree(":",$1,$3);}
    | EXP tk_choice EXP {$$ = buildTree(":",$1,$3);add_quadruple("=",$1->reg_name,"","rx",0);add_quadruple("=",$3->reg_name,"","rx",0);}
    ;

LIT
    : tk_identifier {$$ = buildTree((char *)yylval.sval,0,0); 
                    name=strdup(yylval.sval);/*flag=0;*/ 
                    if(flag){installID(name,"","");flag=0;}
                    int i=search(name);
                    if(i==-1){
                        yyerror();
                        strcpy($$->res, "");
                    }
                    else
                        strcpy($$->res, symbolTable[i].val);
                    if(scope!=0)
                        flag1=1;
                    strcpy($$->reg_name,(char *)yylval.sval);}
    | tk_inumber {$$ = buildTree((char *)yylval.sval,0,0);   value=strdup(yylval.sval); type="int"; strcpy($$->res,(char *)yylval.sval); strcpy($$->reg_name,(char *)yylval.sval);}
    | tk_fnumber {$$ = buildTree((char *)yylval.sval,0,0);   value=strdup(yylval.sval); type="float"; strcpy($$->res,(char *)yylval.sval); strcpy($$->reg_name,(char *)yylval.sval);}
    | tk_true {$$ = buildTree("true",0,0);   value=strdup(yylval.sval);type="boolean"; strcpy($$->res,"1"); strcpy($$->reg_name,"true");}
    | tk_false {$$ = buildTree("false",0,0);   value=strdup(yylval.sval);type="boolean"; strcpy($$->res,"0"); strcpy($$->reg_name,"false");}
    | tk_null {$$ = buildTree("null",0,0);   value=strdup(yylval.sval);type="null"; strcpy($$->res,"0"); strcpy($$->reg_name,"null");}
    | tk_str {$$ = buildTree((char *)yylval.sval,0,0);   value=strdup(yylval.sval); type="string"; strcpy($$->res,(char *)yylval.sval); strcpy($$->reg_name,(char *)yylval.sval);}
    ;

TYPE
    : tk_var
    ;

RELOP
    : tk_l {strcpy($$, yylval.sval);}
    | tk_g {strcpy($$, yylval.sval);}
    | tk_le {strcpy($$, yylval.sval);}
    | tk_ge {strcpy($$, yylval.sval);}
    | tk_neq { strcpy($$, yylval.sval);}
    | tk_deq { strcpy($$, yylval.sval);}
    | tk_teq { strcpy($$, yylval.sval);}
    ;

un_boolop
    : tk_not 
    ;
%%

//-------------------------------------------------------------------AST------------------------------------------------------------------------
// AST builder
node* buildTree(char *op, node *left, node *right) {
    node *x = (node*)malloc(sizeof(node));
    char *newstr = (char*)malloc(strlen(op)+1);
    strcpy(newstr,op);

    x->left=left;
    x->right=right;
    x->name=newstr;

    return x;
}

// AST printer
void printTree(node *tree) {
    if(tree->left || tree->right)
        printf("(");
    
    printf(" %s ",tree->name);
    
    if(tree->left)
        printTree(tree->left);
    
    if(tree->right)
        printTree(tree->right);
    
    if(tree->left || tree->right)
        printf(")");	
}


//--------------------------------------------------------------Symbol table---------------------------------------------------------------------
//Symtab record installer
void installID(char *name, char *value, char *type){
    int x=search(name);
    

    if(x==-1){
        //symbolTable[count]=(struct symTab)malloc(sizeof(struct symTab));
        symbolTable[count].id_name = name;
        symbolTable[count].line_no= line;
        symbolTable[count].scope= scope;
        strcpy(symbolTable[count].val, value);
        symbolTable[count].type= type;

        count+=1;
    }
    else{
        strcpy(symbolTable[x].val,value);
        symbolTable[x].type= type;

    }
    return;
    
}

//Symtab record searcher
int search(char *name){
    for(int i=0;i<count;i++){
        //if(symbolTable[i]!=NULL){
            if(strcmp(symbolTable[i].id_name,name)==0 && symbolTable[i].scope==scope)
                return i;
        //}
    }
    return -1;
}

//Symtab printer
void display(){
    printf("---------------------------------Symbol Table---------------------------------\n");
    printf("name\t|\tline\t|\tscope\t|\tvalue\t\t|\ttype\n");
    printf("------------------------------------------------------------------------------\n");
    for(int i=0;i<count;i++){
        //if(symbolTable[i]!=NULL)
            printf("%s\t|\t%d\t|\t%d\t|\t%s\t\t|\t%s\n",symbolTable[i].id_name, symbolTable[i].line_no, symbolTable[i].scope, symbolTable[i].val, symbolTable[i].type);
    }
}



//----------------------------------------------------------------ICG---------------------------------------------------------------------------
void add_quadruple(char *op,char *arg1,char *arg2,char *result,int option)
{	 
	strcpy(Quad[Index].op,op);
	
	strcpy(Quad[Index].arg1,arg1);
	strcpy(Quad[Index].arg2,arg2);
	if(option == 0)
	{
		strcpy(Quad[Index].result,result);
	}
	else
	{
		sprintf(Quad[Index].result,"r%d",rIndex++);
		strcpy(result,Quad[Index].result); 
	}	
	strcpy(Quad[Index].block,get_top());
    Quad[Index].pos=Index;
	Quad[Index++].scope = scope;
}

void eprint(struct quad quad)
{
    if(strcmp(quad.op,"=") == 0){
        printf("%d.\t%s %s %s\n",quad.pos, quad.result,quad.op,quad.arg1);
        return;
    }
    else
        printf("%d.\t%s %s %s %s %s\n",quad.pos, quad.result, "=", quad.arg1, quad.op, quad.arg2);
    
}

void print_3addr_code()
{
    
    printf("\n------------------------------- Quadruples -----------------------------\n");
	printf("%s\t|\t%s\t|\t%s\t|\t%s\t|\t%s","pos","op","arg1","arg2","result");
	printf("\n------------------------------------------------------------------------");
	for(int i=0;i<Index;i++)
	{
		printf("\n%d\t|\t%s\t|\t%s\t|\t%s\t|\t%s", Quad[i].pos,Quad[i].op, Quad[i].arg1,Quad[i].arg2,Quad[i].result);
	}
	printf("\n\n\n\n");
    

    printf("\nThree address code:\n\n");

    int i=0;
    char *b,*b1;int s,flag=1;
    b=Quad[0].block;
    s=Quad[0].scope;
    struct quad do_cond;

    if(strcmp(b,"")!=0)
        printf("\t%s:\n",b);
    else
        printf("\n");

    while(i<Index){

        if(strcmp(b,"tern")>0){
            struct quad x,y;
            if(flag){
                
                int j=i,k=i;
                while(strcmp(Quad[j].block,b)==0)
                    j+=1;
                x=Quad[j];
                while(strcmp(Quad[k].arg2,"")!=0)
                    k+=1;
                y=Quad[k+1];
                
                printf("\tif !(%s%s%s) goto %d\n",Quad[i].arg1,Quad[i].op,Quad[i].arg2, y.pos);
                flag=0;
            }
            
            if(strcmp(Quad[i].block,b)==0 && Quad[i].pos!=y.pos){
                if(strcmp(Quad[i].result,"")!=0)
                    eprint(Quad[i]);
                i=i+1;
            }
            else if(strcmp(Quad[i].block,b)==0 && Quad[i].pos==y.pos){
                printf("\tgoto %d\n",x.pos);
                if(strcmp(Quad[i].result,"")!=0)
                    eprint(Quad[i]);
                i=i+1;
            }
            else{
                flag=1;
                b=Quad[i].block;
                s=Quad[i].scope;
                if(strcmp(b,"")!=0)
                    printf("\n\t%s:\n",b);
                else
                    printf("\n");
                continue;
            }
            
        }
        else if(strcmp(b,"for")>0){
            
            struct quad x,y,z;
            
            if(flag){
                b1= Quad[i].block;
                int j=i;
                while(strcmp(Quad[j].block,b)==0)
                    j+=1;
                z= Quad[j];
                printf("\tif !(%s%s%s) goto %d\n",Quad[i].arg1,Quad[i].op,Quad[i].arg2, z.pos);
                x=Quad[i+1];
                y=Quad[i+2];
                i=i+3;
                flag=0;
            }

            if(strcmp(Quad[i].block,b)==0){
                if(strcmp(Quad[i].result,"")!=0)
                    eprint(Quad[i]);
                i=i+1;
            }
            else{
                flag=1;
                eprint(x);
                eprint(y);
                printf("\tgoto %s\n",b1);
                b=Quad[i].block;
                s=Quad[i].scope;
                if(strcmp(b,"")!=0)
                    printf("\n\t%s:\t\n",b,s);
                    printf("\n");
                continue;
            }
        
        }
        else if(strcmp(b,"do")>0){
            if(strcmp(Quad[i].block,b)==0){
                if(strcmp(Quad[i].result,"")!=0)
                    eprint(Quad[i]);
                do_cond=Quad[i];
                i=i+1;
            }
            else{
                printf("\tif(%s%s%s) goto %s\n",do_cond.arg1,do_cond.op,do_cond.arg2,b);
                b=Quad[i].block;
                s=Quad[i].scope;
                if(strcmp(b,"")!=0)
                    printf("\n\t%s:\n",b);
                else
                    printf("\n");
                continue;
            }
        }
        else{
            if(strcmp(Quad[i].block,b)==0){
                if(strcmp(Quad[i].result,"")!=0)
                    eprint(Quad[i]);
                i=i+1;
            }
            else{
                b=Quad[i].block;
                s=Quad[i].scope;
                if(strcmp(b,"")!=0)
                    printf("\n\t%s:\n",b);
                else
                    printf("\n");
                continue;
            }
        }   

    }

    printf("\n------------------------------------------------------------------------------\n\n");
}

void push(char *label)
{
	strcpy(stk.label[++stk.top],label);
}

void pop()
{
	stk.top--;
}

char* get_top()
{
	return stk.label[stk.top];
}


//------------------------------------------------------------------MISC-----------------------------------------------------------------------
int getTeq(char *val1, char *val2, char *t1, char* t2){
    char *type1,*type2;
    if(strcmp(val1,val2)!=0)
        return 0;
    else{
        if(strcmp(t1,t2)==0)
            return 1;
        else if(t1[0]=='r' && t2[0]=='r'){
            int i=0,j=0;
            while(i<strlen(val1)){
                if(i==34 || i==39){
                    type1="string";
                    break;
                }
                else if(i=='.'){
                    type1="float";
                    break;
                }
                i+=1;
            }
            if(i==strlen(val1))
                type1="int";

            while(j<strlen(val2)){
                if(j==34 || j==39){
                    type2="string";
                    break;
                }
                if(j=='.'){
                    type2="float";
                    break;
                }
                j+=1;
            }
            if(j==strlen(val2))
                type2="int";

            if(strcmp(type1,type2)==0)
                return 1;
            else
                return 0;
        }
        else
            return 0;
        
    }
}




//-------------------------------------------------------------------MAIN----------------------------------------------------------------------
int main() {
    extern FILE *yyin;

    yyin= fopen("input1.txt","r");

    yyparse();

    sprintf(block,"end");
    push(block);
    add_quadruple("","","","",0);
    pop();

    print_3addr_code();

    display();

    return 1;
}
