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
    FILE *icg;
    FILE *q;

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
    : C statement tk_sc 
    | C LOOPS 
    | statement tk_sc 
    | LOOPS 
    | error tk_sc
    ;

LOOPS
    : tk_do LOOPBODY tk_while tk_opar COND tk_cpar tk_sc 
    | tk_for tk_opar ASSIGN_EXPR tk_sc COND tk_sc statement tk_cpar LOOPBODY 
    ;

COND
    : LIT RELOP LIT add_quadruple
    | LIT 
    | un_boolop LIT 
    ;

LOOPBODY
    : tk_obrace LOOPC tk_cbrace
    | tk_sc 
    | statement tk_sc 
    ;

LOOPC
    : LOOPC statement tk_sc
    | statement tk_sc 
    ;

statement
    : ASSIGN_EXPR 
    | EXP
    | TERNARY_EXPR
    ;

ASSIGN_EXPR
    : LIT tk_eq EXP    
    | TYPE LIT A 
    ;

A
    :
    tk_eq EXP 
    | 
    ;

EXP
    : ADDSUB
    | EXP tk_l ADDSUB 
    | EXP tk_g ADDSUB 
    | EXP tk_le ADDSUB 
    | EXP tk_ge ADDSUB 
    | EXP tk_neq ADDSUB
    | EXP tk_deq ADDSUB
    | EXP tk_teq ADDSUB 
    | EXP tk_and ADDSUB 
    | EXP tk_or ADDSUB 
    ;
	  
ADDSUB
    : TERM 
    | EXP tk_add TERM 
    | EXP tk_sub TERM 
    ;

TERM
    : FACTOR
    | TERM tk_mul FACTOR 
    | TERM tk_div FACTOR 
    | TERM tk_mod FACTOR 
    ;
      
FACTOR
    : LIT 
    | tk_opar EXP tk_cpar
    ;
      
TERNARY_EXPR
    : tk_opar COND tk_cpar tk_tern ternary_statement 
    ;

ternary_statement
    : ASSIGN_EXPR tk_choice ASSIGN_EXPR 
    | EXP tk_choice EXP 
    | ASSIGN_EXPR tk_choice EXP 
    | EXP tk_choice ASSIGN_EXPR 
    ;

LIT
    : tk_identifier 
    | tk_inumber 
    | tk_fnumber 
    | tk_true 
    | tk_false 
    | tk_null 
    | tk_str 
    ;

TYPE
    : tk_var
    ;

RELOP
    : tk_l 
    | tk_g 
    | tk_le
    | tk_ge 
    | tk_neq
    | tk_deq
    | tk_teq
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
		sprintf(Quad[Index].result,"t%d",rIndex++);
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
        fprintf(icg, "%d.\t%s %s %s\n",quad.pos, quad.result,quad.op,quad.arg1);
        return;
    }
    else{
        printf("%d.\t%s %s %s %s %s\n",quad.pos, quad.result, "=", quad.arg1, quad.op, quad.arg2);
        fprintf(icg, "%d.\t%s %s %s %s %s\n",quad.pos, quad.result, "=", quad.arg1, quad.op, quad.arg2);
    }
    
}

void print_3addr_code()
{
    icg=fopen("/Users/shreyasbs/Desktop/Academic/Sem6/CD/Project/target/icg.txt","w");
    fclose(icg);

    q=fopen("/Users/shreyasbs/Desktop/Academic/Sem6/CD/Project/target/quad.txt","w");
    fclose(q);

    icg=fopen("/Users/shreyasbs/Desktop/Academic/Sem6/CD/Project/target/icg.txt","a");
    q=fopen("/Users/shreyasbs/Desktop/Academic/Sem6/CD/Project/target/quad.txt","a");

    printf("\n----------------------------------- Quadruples ---------------------------------\n");
	printf("%s\t|\t%s\t|\t%s\t|\t%s\t|\t%s\t|\t%s\t|\t%s","pos","op","arg1","arg2","result","block","scope");
	printf("\n--------------------------------------------------------------------------------");
	for(int i=0;i<Index;i++)
	{
		printf("\n%d\t|\t%s\t|\t%s\t|\t%s\t|\t%s\t|\t%s\t|\t%d", Quad[i].pos,Quad[i].op, Quad[i].arg1,Quad[i].arg2,Quad[i].result,Quad[i].block,Quad[i].scope);
        fprintf(q,"\n%d;%s;%s;%s;%s;%s;%d", Quad[i].pos,Quad[i].op, Quad[i].result, Quad[i].arg1,Quad[i].arg2, Quad[i].block, Quad[i].scope);
	}
	printf("\n\n\n\n");
    

    printf("\nThree address code:\n\n");

    int i=0;
    char *b,*b1;int s,flag=1;
    b=Quad[0].block;
    s=Quad[0].scope;
    struct quad do_cond;

    if(strcmp(b,"")!=0){
        printf("\t%s:\n",b);
        fprintf(icg,"\t%s:\n",b);
    }
    else{
        printf("\n");
        fprintf(icg,"\n");
    }

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
                fprintf(icg,"\tif !(%s%s%s) goto %d\n",Quad[i].arg1,Quad[i].op,Quad[i].arg2, y.pos);
                flag=0;
            }
            
            if(strcmp(Quad[i].block,b)==0 && Quad[i].pos!=y.pos){
                if(strcmp(Quad[i].result,"")!=0)
                    eprint(Quad[i]);
                i=i+1;
            }
            else if(strcmp(Quad[i].block,b)==0 && Quad[i].pos==y.pos){
                printf("\tgoto %d\n",x.pos);
                fprintf(icg, "\tgoto %d\n",x.pos);
                if(strcmp(Quad[i].result,"")!=0)
                    eprint(Quad[i]);
                i=i+1;
            }
            else{
                flag=1;
                b=Quad[i].block;
                s=Quad[i].scope;
                if(strcmp(b,"")!=0){
                    printf("\n\t%s:\n",b);
                    fprintf(icg, "\n\t%s:\n",b);
                }
                else{
                    printf("\n");
                    fprintf(icg, "\n");
                }
                continue;
            }
            
        }
        else if(strcmp(b,"for")>0){
            
            struct quad z;int start,end;
            
            if(flag){
                b1= Quad[i].block;
                int j=i;
                while(strcmp(Quad[j].block,b)==0)
                    j+=1;
                z= Quad[j];
                printf("\tif !(%s%s%s) goto %d\n",Quad[i].arg1,Quad[i].op,Quad[i].arg2, z.pos);
                fprintf(icg, "\tif !(%s%s%s) goto %d\n",Quad[i].arg1,Quad[i].op,Quad[i].arg2, z.pos);

                i=i+1;
                start=i;
                while(strcmp(Quad[i].arg2,"")!=0){
                    i+=1;}
                end=i;
                i=i+1;
                flag=0;
            }

            if(strcmp(Quad[i].block,b)==0){
                if(strcmp(Quad[i].result,"")!=0)
                    eprint(Quad[i]);
                i=i+1;
            }
            else{
                flag=1;
                for(int x=start;x<end+1;x++)
                    eprint(Quad[x]);
                
                //eprint(x);
                //eprint(y);
                printf("\tgoto %s\n",b1);
                fprintf(icg, "\tgoto %s\n",b1);
                b=Quad[i].block;
                s=Quad[i].scope;
                if(strcmp(b,"")!=0){
                    printf("\n\t%s:\t\n",b,s);
                    fprintf(icg, "\n\t%s:\t\n",b,s);
                }
                printf("\n");
                fprintf(icg, "\n");
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
                fprintf(icg, "\tif(%s%s%s) goto %s\n",do_cond.arg1,do_cond.op,do_cond.arg2,b);
                b=Quad[i].block;
                s=Quad[i].scope;
                if(strcmp(b,"")!=0){
                    printf("\n\t%s:\n",b);
                    fprintf(icg, "\n\t%s:\n",b);
                }
                else{
                    printf("\n");
                    fprintf(icg, "\n");
                }
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
                if(strcmp(b,"")!=0){
                    printf("\n\t%s:\n",b);
                    fprintf(icg, "\n\t%s:\n",b);
                }
                else{
                    printf("\n");
                    fprintf(icg, "\n");
                }
                continue;
            }
        }   

    }

    printf("\n------------------------------------------------------------------------------\n\n");
    fclose(q);
    fclose(icg);
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

    yyin= fopen("input.txt","r");

    yyparse();

    sprintf(block,"end");
    push(block);
    add_quadruple("","","","",0);
    pop();

    print_3addr_code();

    display();

    return 1;
}
