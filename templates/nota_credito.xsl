<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:tmp="urn:oasis:names:specification:ubl:schema:xsd:CreditNote-2"
                xmlns:cac="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2"
                xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2"
                xmlns:ds="http://www.w3.org/2000/09/xmldsig#"
                xmlns:ext="urn:oasis:names:specification:ubl:schema:xsd:CommonExtensionComponents-2"
                xmlns:sac="urn:sunat:names:specification:ubl:peru:schema:xsd:SunatAggregateComponents-1"
                version="1.0">
    <xsl:output method="html"
                doctype-system="http://www.w3.org/TR/html4/strict.dtd"
                doctype-public="-//W3C//DTD HTML 4.01//EN"
                indent="yes"/>
    <xsl:decimal-format name="money"
                        decimal-separator="."
                        grouping-separator=","/>
    <xsl:template match="/tmp:CreditNote">
        <html>
            <head>
                <title> Nota de Crédito Electrónica - <xsl:value-of select="cbc:ID"/>
                </title>
                <link rel="stylesheet"
                      type="text/css"
                      href="nota_credito.css"/>
            </head>
            <body>
                <div style="width: 700px; margin: 0 auto; position: relative;">
                    <div style="padding:5px; border: #4682b4 1px solid;">
                        <div id="etiqueta">
                            <xsl:call-template name="nombre_factura_guia"/>
                        </div>
                        <div id="cabecera">
                            <div id="emisor">
                                <xsl:call-template name="emisor"/>
                            </div>
                        </div>
                        <br/>
                        <div id="contenido">
                            <div class="receptor">
                                <xsl:call-template name="receptor"/>
                                <br/>
                            </div>                            
                            <br/>
                            <div class="detalle">
                                <label> Detalle: </label>
                                <br/>
                                <xsl:call-template name="detalle"/>
                                <br/>
                            </div>
                            <!-- Subtotales -->
                            <div>
                                <div class="subtotal">
									<!-- Subtotales - Sub total Ventas -->
                                    <label class="subtotal_nombre">Sub total Ventas:</label>
                                    <label class="subtotal_valor">
                                        <xsl:call-template name="SimboloMonedaCatalogo">
                                            <xsl:with-param name="SimboloMoneda" select="cbc:DocumentCurrencyCode"/>
                                        </xsl:call-template>
                                        <xsl:value-of select="format-number(cac:LegalMonetaryTotal/cbc:LineExtensionAmount + cac:LegalMonetaryTotal/cbc:PrepaidAmount + cac:LegalMonetaryTotal/cbc:AllowanceTotalAmount ,  '#,##0.00')"/>
                                    </label>
                                    <br/>
									<!-- Subtotales - Anticipos -->
                                    <xsl:if test="cac:LegalMonetaryTotal/cbc:PrepaidAmount">
                                        <label class="subtotal_nombre">Anticipos</label>
                                        <label class="subtotal_valor">
                                            <xsl:call-template name="SimboloMonedaCatalogo">
                                                <xsl:with-param name="SimboloMoneda" select="cbc:DocumentCurrencyCode"/>
                                            </xsl:call-template>
                                            <xsl:value-of select="format-number(cac:LegalMonetaryTotal/cbc:PrepaidAmount, '#,##0.00')"/>
                                        </label>
                                        <br/>
                                    </xsl:if>
                                    <!-- Subtotales - Descuentos -->
                                    <xsl:if test="cac:LegalMonetaryTotal/cbc:AllowanceTotalAmount">
                                        <label class="subtotal_nombre">Descuentos:</label>
                                        <label class="subtotal_valor">
                                            <xsl:call-template name="SimboloMonedaCatalogo">
                                                <xsl:with-param name="SimboloMoneda" select="cbc:DocumentCurrencyCode"/>
                                            </xsl:call-template>
                                            <xsl:value-of select="format-number(cac:LegalMonetaryTotal/cbc:AllowanceTotalAmount, '#,##0.00')"/>
                                        </label>
                                        <br/>
                                    </xsl:if>
                                    <!-- Subtotales - Valor de venta -->
                                    <xsl:if test="cac:LegalMonetaryTotal/cbc:LineExtensionAmount">
                                        <label class="subtotal_nombre">Valor de venta:</label>
                                        <label class="subtotal_valor">
                                            <xsl:call-template name="SimboloMonedaCatalogo">
                                                <xsl:with-param name="SimboloMoneda"
                                                                select="cbc:DocumentCurrencyCode"/>
                                            </xsl:call-template>
											<xsl:value-of select="format-number(cac:LegalMonetaryTotal/cbc:LineExtensionAmount, '#,##0.00')"/> 
                                        </label>
                                        <br/>
                                    </xsl:if>
                                    <!-- Subtotales - IGV -->
                                    <xsl:if test="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID=1000]/cbc:TaxAmount">
                                        <label class="subtotal_nombre">IGV:</label>
                                        <label class="subtotal_valor">
                                            <xsl:call-template name="SimboloMonedaCatalogo">
                                                <xsl:with-param name="SimboloMoneda"
                                                                select="cbc:DocumentCurrencyCode"/>
                                            </xsl:call-template>
                                            <xsl:value-of select="format-number(cac:TaxTotal[cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID=1000]/cbc:TaxAmount, '#,##0.00')"/>
                                        </label>
                                        <br/>
                                    </xsl:if>
                                    <!-- Subtotales - ISC -->
                                    <xsl:if test="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID=2000]/cbc:TaxAmount">
                                        <label class="subtotal_nombre">ISC:</label>
                                        <label class="subtotal_valor">
                                            <xsl:call-template name="SimboloMonedaCatalogo">
                                                <xsl:with-param name="SimboloMoneda"
                                                                select="cbc:DocumentCurrencyCode"/>
                                            </xsl:call-template>
                                            <xsl:value-of select="format-number(cac:TaxTotal[cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID=2000]/cbc:TaxAmount, '#,##0.00')"/>
                                        </label>
                                        <br/>
                                    </xsl:if>
									<!-- Subtotales - Impuesto ICBPER -->
									<xsl:if test="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID=7152]/cbc:TaxAmount">
										<label class="subtotal_nombre">Impuesto ICBPER:</label>
                                        <label class="subtotal_valor">
                                            <xsl:call-template name="SimboloMonedaCatalogo">
                                                <xsl:with-param name="SimboloMoneda" select="cbc:DocumentCurrencyCode"/>
                                            </xsl:call-template>
                                            <xsl:value-of select="format-number(cac:TaxTotal[cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID=7152]/cac:TaxSubtotal/cbc:TaxAmount, '#,##0.00')"/>
                                        </label>
                                        <br/>
									</xsl:if>
                                    <!-- Subtotales - Otros cargos -->
                                    <xsl:if test="cac:LegalMonetaryTotal/cbc:ChargeTotalAmount">
                                        <label class="subtotal_nombre">Otros cargos :</label>
                                        <label class="subtotal_valor">
                                            <xsl:call-template name="SimboloMonedaCatalogo">
                                                <xsl:with-param name="SimboloMoneda"
                                                                select="cbc:DocumentCurrencyCode"/>
                                            </xsl:call-template>
                                            <xsl:value-of select="format-number(cac:LegalMonetaryTotal/cbc:ChargeTotalAmount, '#,##0.00')"/>
                                        </label>
                                        <br/>
                                    </xsl:if>
									<!-- Subtotales - Otros tributos -->
                                    <xsl:if test="cac:TaxTotal[cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID=9999]/cbc:TaxAmount">
                                        <label class="subtotal_nombre">Otros tributos:</label>
                                        <label class="subtotal_valor">
                                            <xsl:call-template name="SimboloMonedaCatalogo">
                                                <xsl:with-param name="SimboloMoneda"
                                                                select="cbc:DocumentCurrencyCode"/>
                                            </xsl:call-template>
                                            <xsl:value-of select="format-number(cac:TaxTotal[cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID=9999]/cbc:TaxAmount, '#,##0.00')"/>
                                        </label>
                                        <br/>
                                    </xsl:if>

                                    <!--Subtotales - Monto de redondeo-->
                                    <xsl:if test="cac:LegalMonetaryTotal/cbc:PayableRoundingAmount">
                                        <label class="subtotal_nombre">Monto de redondeo :</label>
                                        <label class="subtotal_valor">
                                            <xsl:call-template name="SimboloMonedaCatalogo">
                                                <xsl:with-param name="SimboloMoneda"
                                                                select="cbc:DocumentCurrencyCode"/>
                                            </xsl:call-template>
                                            <xsl:value-of select="format-number(cac:LegalMonetaryTotal/cbc:PayableRoundingAmount, '#,##0.00')"/>
                                        </label>
                                        <br/>
                                    </xsl:if>
                                    <!--Subtotales - Monto de redondeo-->


                                    <!-- Subtotales - Importe total -->
                                    <label class="subtotal_nombre">Importe total :</label>
                                    <label class="subtotal_valor">
                                        <xsl:call-template name="SimboloMonedaCatalogo">
                                            <xsl:with-param name="SimboloMoneda"
                                                            select="cbc:DocumentCurrencyCode"/>
                                        </xsl:call-template>
                                        <xsl:value-of select="format-number(cac:LegalMonetaryTotal/cbc:PayableAmount, '#,##0.00')"/>
                                    </label>
                                    <br/>
                                    <!-- /xsl:if -->
                                </div>
                                <!-- Monto en letras -->
                                <div class="leyenda_izquierda">
                                    <!-- Operaciones Gratuitas -->
                                    <xsl:if test="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID=9996]/cbc:TaxableAmount">
                                        <div>    
                                            <label class="subtotal_nombre">Valor Op.Gratuitas:</label>                                        
                                           
                                            <xsl:call-template name="SimboloMonedaCatalogo">
                                                <xsl:with-param name="SimboloMoneda"
                                                                select="cbc:DocumentCurrencyCode"/>
                                            </xsl:call-template>
                                            <xsl:value-of select="format-number(cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID=9996]/cbc:TaxableAmount, '#,##0.00')"/>
                                          
                                        </div>
                                        <br/>
                                    </xsl:if>
                                    <div class="negrita">
                                        <xsl:value-of select="cbc:Note[@languageLocaleID='1000']"/>
                                        <br/>
                                    </div>
                                    <div>
                                        <br/>
                                        <xsl:if test="cbc:Note[@languageLocaleID='5000']">
                                            Número de Expediente: <xsl:value-of select="cbc:Note[@languageLocaleID='5000']"/>
                                            <br/>
                                        </xsl:if>
                                        <xsl:if test="cbc:Note[@languageLocaleID='5001']">
                                            Código de unidad ejecutora: <xsl:value-of select="cbc:Note[@languageLocaleID='5001']"/>
                                            <br/>
                                        </xsl:if>
                                        <xsl:if test="cbc:Note[@languageLocaleID='5002']">
                                            Número del Proceso de Selección: <xsl:value-of select="cbc:Note[@languageLocaleID='5002']"/>
                                            <br/>
                                        </xsl:if>
                                        <xsl:if test="cbc:Note[@languageLocaleID='5003']">
                                            Número de Contrato: <xsl:value-of select="cbc:Note[@languageLocaleID='5003']"/>
                                            <br/>
                                        </xsl:if>
                                    </div>                                   
                                </div>
                            </div>
                        </div>
                        <div style="clear:right;"/>
                        <br/>
                        <div style="clear:left;"/>  
                        <br/>
						<xsl:if test="cac:PaymentTerms/cbc:PaymentMeansID">
						<xsl:if test="cac:PaymentTerms/cbc:PaymentMeansID='Credito' and cac:DiscrepancyResponse/cbc:Description!='Otros Conceptos'"  >
						<div id="cuotas">
                            <div class="cuotas">
                                <xsl:call-template name="cuotas"/>
                            </div>
                        </div>
						</xsl:if>
						<br/>
						<xsl:if test="cac:DiscrepancyResponse/cbc:Description='Otros Conceptos'"  >
						<div id="retencion">
                            <div class="retencion">
                                <xsl:call-template name="retencion"/>
                            </div>
                        </div>
						</xsl:if>
						<br/>	
						</xsl:if>						
                        <div id="representacion_impresa">
                            <xsl:call-template name="representacion_impresa"/>
                        </div>
                        <br/>
                    </div>
                </div>
            </body>
        </html>
    </xsl:template>
    <!-- template con informacion de la guia-->
    <xsl:template name="nombre_factura_guia">
        <xsl:choose>
            <xsl:when test="cbc:InvoiceTypeCode = '03'">
                GUÍA DE REMISIÓN ELECTRÓNICA BF REMITENTE  <br/>
            </xsl:when>
            <xsl:when test="cbc:InvoiceTypeCode = '01'">
                FACTURA ELECTRONICA <br/>
            </xsl:when>
            <xsl:when test="cbc:InvoiceTypeCode = '62'">
                GUÍA DE REMISIÓN ELECTRÓNICA BF TRANSPORTISTA  <br/>
            </xsl:when>
            <xsl:when test="cbc:InvoiceTypeCode = '62'">
                GUÍA DE REMISIÓN ELECTRÓNICA BF TRANSPORTISTA COMPLEMENTARIA <br/>
            </xsl:when>
            <xsl:otherwise>
                NOTA DE CRÉDITO ELECTRÓNICA <br/>
            </xsl:otherwise>
        </xsl:choose>
        RUC : <xsl:value-of select="cac:AccountingSupplierParty/cac:Party/cac:PartyIdentification/cbc:ID"/>
        <br/>
        <xsl:value-of select="cbc:ID"/>
    </xsl:template>
    <!-- template del remitente -->
    <xsl:template name="emisor">
        <h4>
            <xsl:value-of select="cac:AccountingSupplierParty/cac:Party/cac:PartyName/cbc:Name"/> 
        </h4>
        <h4>
            <xsl:value-of select="cac:AccountingSupplierParty/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName"/>
        </h4>
        <xsl:value-of select="cac:AccountingSupplierParty/cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cac:AddressLine/cbc:Line"/>
        <br/>
        <xsl:call-template name="ubigeo">
            <xsl:with-param name="Address"
                            select="cac:AccountingSupplierParty/cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress"/>
        </xsl:call-template>
    </xsl:template>
    <!-- Template Datos del Cliente  -->
    <xsl:template name="receptor">
        <b>DATOS DEL CLIENTE</b>
        <div>

                <div class="doc_relacionados">
                    <xsl:call-template name="tipoNota"/>
                    <br/>
                </div>

            <!-- template del receptor -->
            <xsl:if test="cbc:DueDate">
                <label>F.Vencimiento :</label>
                <xsl:call-template name="formatFecha">
                    <xsl:with-param name="Fecha"
                                    select="cbc:DueDate"/>
                </xsl:call-template>
                <br/>
            </xsl:if>
            <label>F. Emisión :</label>
            <xsl:call-template name="formatFecha">
                <xsl:with-param name="Fecha"
                                select="cbc:IssueDate"/>
            </xsl:call-template>
            <br/>
            <label>Señor(es):</label>
            <label class="valor">
                <xsl:value-of select="cac:AccountingCustomerParty/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName"/>
            </label>
            <br/>
            <label>
                <xsl:call-template name="TipoDocIdentidad">
                    <xsl:with-param name="TipoDocIdentidad"
                                    select="cac:AccountingCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID/@schemeID"/>
                </xsl:call-template>
            </label>
            <label class="negrita">
                <xsl:value-of select="cac:AccountingCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID"/>
            </label>
            <br/>
            <xsl:choose>
                <xsl:when test="cac:PaymentTerms/cbc:PaymentMeansID='Credito'">
                    <xsl:if test="cac:BuyerCustomerParty/cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cac:AddressLine/cbc:Line">
                        <label>Dirección del Receptor de la Factura :</label>
                        <label class="valor">
                            <xsl:value-of select="cac:BuyerCustomerParty/cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cac:AddressLine/cbc:Line"/>
                        </label>
                        <br/>
                    </xsl:if>
                </xsl:when>
            <xsl:otherwise>
                <xsl:if test="cac:AccountingSupplierParty/cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cac:AddressLine/cbc:Line">
					<label>Dirección del cliente :</label>
					<label class="valor">
						<xsl:value-of select="cac:AccountingSupplierParty/cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cac:AddressLine/cbc:Line"/>
					</label>
					<br/>
				</xsl:if>
            </xsl:otherwise>
            </xsl:choose>
            <label>Moneda :</label>
            <label class="negrita">
                <xsl:call-template name="MonedaCatalogo">
                    <xsl:with-param name="SimboloMoneda" select="cbc:DocumentCurrencyCode"/>
                </xsl:call-template>
            </label>
            <br/>
            <!-- Documento afectado-->
             <xsl:if test="cac:DiscrepancyResponse/cbc:Description">
                <label>Motivo :</label>
                <label class="valor">
                    <xsl:value-of select="cac:DiscrepancyResponse/cbc:Description"/>
                </label>
                <br/>
            </xsl:if>
            <xsl:if test="cac:DiscrepancyResponse/cbc:ReferenceID">
                <label>Doc. Afectado :</label>
                <label class="valor">
                    <xsl:value-of select="cac:DiscrepancyResponse/cbc:ReferenceID"/>
                </label>
                <br/>
            </xsl:if>
            <xsl:if test="cac:BillingReference/cac:InvoiceDocumentReference/cbc:IssueDate">
                <label>Emitida :</label>
                <label class="valor">
                    <xsl:value-of select="cac:BillingReference/cac:InvoiceDocumentReference/cbc:IssueDate"/>
                </label>
                <br/>
            </xsl:if>
            <br/>
            <!-- Observaciones -->
            <xsl:if test="cbc:Note[not(@*)]">
                <div>
                    <label> Observaciones:</label>
                    <xsl:value-of select="cbc:Note[not(@*)]"/>
                </div>
            </xsl:if>
            

        </div>
    
    </xsl:template>
    <xsl:template name="tipoNota">
        <div>
			<xsl:if test="cac:DiscrepancyResponse/cbc:ResponseCode='13'">
			<b>NC Ajustes - montos y/o fechas de pago</b>   
			</xsl:if>
	        
			<xsl:if test="cac:DiscrepancyResponse/cbc:ResponseCode='10'">
			<b>Otros Conceptos</b>   
			</xsl:if>		
        </div>
    </xsl:template>	
	
	
    <!-- Template documentos Relacionados  -->
    <xsl:template name="docRelacionados">
       
        <div>
           
            <xsl:for-each select="cac:DespatchDocumentReference">
                <div>
                    <xsl:value-of select="cbc:DocumentType"/>:<xsl:value-of select="cbc:ID"/>
                    <br/>
                </div>                
            </xsl:for-each>														
            <xsl:for-each select="cac:AdditionalDocumentReference"> 
                <div>
                    <xsl:call-template name="DocumentTypeCatalogo">
                        <xsl:with-param name="DocumentTypeCode"
                                        select="cbc:DocumentTypeCode"/>
                    </xsl:call-template>
                    :<xsl:value-of select="cbc:ID"/>
                    <br/>
                </div>                   
            </xsl:for-each>        
        </div>
    </xsl:template>
    
	<!-- template de cuotas -->
    <xsl:template name="cuotas"> 
	<xsl:variable name="totalCuotas" select="number(count(cac:PaymentTerms[substring(cbc:PaymentMeansID/text(),1,5) = 'Cuota']))"/>						
		<tr>
			<td width="30%" align="left">
				<table width="100%">
					<tbody>
						<tr align="left">
							<td width="31%"><b>Informacion del credito</b></td>
							<td width="3%">:</td>
							<td width="66%"></td>
						</tr>
						<tr align="left">
							<td width="31%">Monto neto pendiente de pago</td>
							<td width="3%">:</td>
							<td width="66%">
								<xsl:call-template name="SimboloMonedaCatalogo">
									<xsl:with-param name="SimboloMoneda" select="cbc:DocumentCurrencyCode"/>
								</xsl:call-template>
								<xsl:value-of select="format-number(cac:PaymentTerms/cbc:Amount, '#,##0.00')"/>
							</td>
						</tr>
						<tr align="left">
							<td>Total de Cuotas</td>
							<td>:</td>
							<td><xsl:value-of select="$totalCuotas"/>
							</td>
						</tr>

					</tbody>
				</table>
			</td>
		</tr>	
		<!-- nro_cuotas = xsl:value-of select="count(cac:PaymentTerms[substring(cbc:PaymentMeansID/text(),1,5) = 'Cuota'])" -->
		<!-- cantXcolumna = nro_cuotas/3  -->
		<tr align="center">
			<td>
				<div style="overflow:auto">
				<table width="65%" class="boxHeader" >
					<tr align="center">
					<xsl:variable name="minLista" select="1" />					
					<xsl:variable name="maxColumna" select="ceiling($totalCuotas div 3)"/>
					
					<!-- for-each 1 - cantXcolumna  -->	
				<xsl:if test="cac:PaymentTerms">
				
					<td>	
					<table>				
						<tr align="center" style="outline: thin solid">
							<td align="center"><b>Nro. Cuota</b></td>
							<td align="center"><b>Fec. Venc.</b></td>
							<td align="left"><b>Monto</b></td>
						</tr>					
						<xsl:for-each select="cac:PaymentTerms[substring(cbc:PaymentMeansID,1,5)='Cuota']">					
							<xsl:if test="position() &lt; $maxColumna+1 and position() &gt; 0">
								<tr>
									<tr align="center">
										<td  align="center"><xsl:value-of select="format-number(substring(cbc:PaymentMeansID/text(),6,8), '#')" /></td>
										<td align="center"><xsl:value-of select="cbc:PaymentDueDate" /></td>
										<td align="left"><xsl:value-of select="format-number(cbc:Amount, '#,##0.00')" /></td>
									</tr>	
								</tr>							
							</xsl:if>
						</xsl:for-each>
					</table>					
					</td>
					
					
					<td>	
					<table>				
						<tr align="center" style="outline: thin solid">
							<td align="center"><b>Nro. Cuota</b></td>
							<td align="center"><b>Fec. Venc.</b></td>
							<td align="left"><b>Monto</b></td>
						</tr>	
						<xsl:if test="$totalCuotas &gt; 1 ">		
						<xsl:for-each select="cac:PaymentTerms[substring(cbc:PaymentMeansID,1,5)='Cuota']">					
							<xsl:if test="position() &lt; ($maxColumna*2)+1 and position() &gt; $maxColumna">
								<tr>
									<tr align="left">
										<td  align="center"><xsl:value-of select="format-number(substring(cbc:PaymentMeansID/text(),6,8), '#')"/></td>
										<td align="center"><xsl:value-of select="cbc:PaymentDueDate" /></td>
										<td align="left"><xsl:value-of select="format-number(cbc:Amount, '#,##0.00')" /></td>
									</tr>	
								</tr>							
							</xsl:if>
						</xsl:for-each>
						</xsl:if>
						<xsl:if test="$totalCuotas = 1">
									<tr>
										<tr>
										
											<td align="center"><xsl:text>&#160;</xsl:text></td>
										</tr>	
									</tr>								
						</xsl:if>
					</table>					
					</td>
					<td>	
					<table>				
						<tr align="center" style="outline: thin solid">
							<td align="center"><b>Nro. Cuota</b></td>
							<td align="center"><b>Fec. Venc.</b></td>
							<td align="left"><b>Monto</b></td>
						</tr>	
						<xsl:if test="$totalCuotas &gt; 2 ">						
						<xsl:for-each select="cac:PaymentTerms[substring(cbc:PaymentMeansID,1,5)='Cuota']">					
							<xsl:if test="position() &lt; ($maxColumna*3)+1 and position() &gt; $maxColumna*2">
								<xsl:if test="$totalCuotas &gt;= position()">							
									<tr>
										<tr align="left">
											<td  align="center"><xsl:value-of select="format-number(substring(cbc:PaymentMeansID/text(),6,8), '#')"/></td>
											<td align="center"><xsl:value-of select="cbc:PaymentDueDate" /></td>
											<td align="left"><xsl:value-of select="format-number(cbc:Amount, '#,##0.00')" /></td>
										</tr>	
									</tr>	
								</xsl:if>
								<!--
								<xsl:if test="$totalCuotas &lt;= position() and position() &lt; $maxColumna*3 ">
									<tr>
										<tr>
											<td align="center"><xsl:text>&#160;</xsl:text></td>
										</tr>	
									</tr>								
								</xsl:if>
								-->

																
							</xsl:if>
						</xsl:for-each>
						</xsl:if>
						<xsl:if test=" $totalCuotas = 1">
									<tr>
										<tr>
										
											<td align="center"><xsl:text>&#160;</xsl:text></td>
										</tr>	
									</tr>								
						</xsl:if>
	

						<xsl:if test="$maxColumna*3 - $totalCuotas   = 2  and  $totalCuotas &gt; 2">
									<tr>
										<tr>
											<td align="center"><xsl:text>&#160;</xsl:text></td>
										</tr>	
										<tr>
											<td align="center"><xsl:text>&#160;</xsl:text></td>
										</tr>
									</tr>								
						</xsl:if>
						
						
						<xsl:if test="$maxColumna*3 - $totalCuotas   = 1  and  $totalCuotas &gt; 1">
									<tr>
										<tr>
											<td align="center"><xsl:text>&#160;</xsl:text></td>
										</tr>	
									</tr>								
						</xsl:if>
						

						
					</table>					
					</td>					
					</xsl:if>
					</tr>
				</table>
				</div> 
			</td>
		</tr>	
	</xsl:template>		
	
	<xsl:template name="retencion">

	
	<xsl:if test="cac:AllowanceCharge[cbc:AllowanceChargeReasonCode = '62']">
	
		<tr>
			<td width="30%" align="left">
				<table width="100%">
					<tbody>
						<tr align="left">
							<td><b>Información de la retención:</b></td>
						</tr>
						<tr align="left">
							<td align="center">Base imponible de la Retención:</td>
							<td align="left"><xsl:value-of select="format-number(cac:AllowanceCharge/cbc:BaseAmount, '#,##0.00')"/></td>
							<td align="center">Porcentaje de retención:</td>
							<td align="left"><xsl:value-of select="concat('% ',cac:AllowanceCharge/cbc:MultiplierFactorNumeric)"/></td>
							<td align="center">Monto de la retención:</td>
							<td align="left"><xsl:value-of select="format-number(cac:AllowanceCharge/cbc:Amount, '#,##0.00')"/></td>
						</tr>
						
					</tbody>
				</table>
			</td>
		</tr>
	</xsl:if>
    </xsl:template>	
	
    <!-- template del pie pagina -->
    <xsl:template name="representacion_impresa">
        <div class="representacion_impresa">Es una representación impresa de la Nota de Crédito Electrónica generada en el sistema de SUNAT. Puede verificarla utilizando la Clave Sol</div>
    </xsl:template>
    <!-- Formato de fecha  -->
    <xsl:template name="formatFecha">
        <xsl:param name="Fecha"/>
        <xsl:value-of select="concat(substring($Fecha, 9, 2),    '/',    substring($Fecha, 6, 2),    '/',    substring($Fecha, 1, 4)    )"/>
    </xsl:template>
    <!-- Formato de fecha  -->
    <xsl:template name="formatTiempo">
        <xsl:param name="Tiempo"/>
        <xsl:value-of select="concat(substring($Tiempo, 1, 2),    ':',    substring($Tiempo, 4, 2)    )"/>
    </xsl:template>
    <!-- Template inicio del traslado  -->
    <xsl:template name="inicioTraslado">
        <b>DATOS DEL INICIO DEL TRASLADO</b>
        <div>
            <label>Fecha de Emisión:</label>
            <xsl:call-template name="formatFecha">
                <xsl:with-param name="Fecha"
                                select="cbc:IssueDate"/>
            </xsl:call-template>
            <br/>
            <xsl:choose>
                <xsl:when test="cbc:TransportModeCode = 1"><!-- si es publico -->
                    <label>Fecha y hora de entrega de bienes al transportista:</label>
                    <xsl:call-template name="formatFecha">
                        <xsl:with-param name="Fecha"
                                        select="sac:DeliveryCarrierDate"/>
                    </xsl:call-template>
                    
                    <xsl:call-template name="formatTiempo">
                        <xsl:with-param name="Tiempo"
                                        select="sac:DeliveryCarrierTime"/>
                    </xsl:call-template>
                    <br/>
                </xsl:when>
                <xsl:otherwise><!-- si es privado -->
                    <label>Fecha y hora de inicio del traslado:</label>
                    <xsl:call-template name="formatFecha">
                        <xsl:with-param name="Fecha"
                                        select="cbc:DespatchDate"/>
                    </xsl:call-template>
                    
                    <xsl:call-template name="formatTiempo">
                        <xsl:with-param name="Tiempo"
                                        select="cbc:DespatchTime"/>
                    </xsl:call-template>
                    <br/>
                </xsl:otherwise>
            </xsl:choose>
            <label>Dirección del punto de partida:</label>
            <br/>
            <xsl:call-template name="direccion">
                <xsl:with-param name="Address"
                                select="sac:SUNATShipment/cac:OriginAddress"/>
            </xsl:call-template>
            <br/>
            <xsl:choose>
                <xsl:when test="cbc:DespatchAdviceTypeCode = '60'">
                    <label>Motivo del traslado:</label>
                    <xsl:call-template name="motivoTraslado"/>
                </xsl:when>
                <xsl:when test="cbc:DespatchAdviceTypeCode = '61'">
                    <label>Motivo:</label>
                    <xsl:call-template name="motivoEmision"/>
                </xsl:when>
                <xsl:otherwise>
                </xsl:otherwise>
            </xsl:choose>
            <br/>
            <label>Modalidad de trasporte:</label>
            <xsl:call-template name="modalidadTraslado"/>
            <br/>
            <xsl:if test="sac:MultiStageIndicator = 'true'">
                <label>Transbordo programado</label>
                <br/>
            </xsl:if>
            <xsl:if test="sac:OriginalDespatchDocumentReference/cbc:ID">
                <label>Guía de remisión electrónica de referencia:</label>
                <xsl:value-of select="sac:OriginalDespatchDocumentReference/cbc:ID"/>
                <br/>
            </xsl:if>
        </div>
    </xsl:template>
    <!-- template del vehiculo -->
    <xsl:template name="vehiculo">
        <table>
            <tr class="beta">
                <td>Nro</td>
                <td>Tipo</td>
                <td>Marca</td>
                <td>Nro. placa</td>
                <td>Nro. inscripción del MTC</td>
            </tr>
            <xsl:for-each select="sac:SUNATShipment/sac:SUNATShipmentStage/sac:SUNATTransportMeans/sac:SUNATRoadTransport">
                <tr>
                    <td>
                        <xsl:value-of select="position()"/>
                    </td>
                    <td>
                        <xsl:call-template name="TipoVehiculo">
                            <xsl:with-param name="TipoVehiculo"
                                            select="cbc:TransportMeansTypeCode"/>
                        </xsl:call-template>
                    </td>
                    <td>
                        <xsl:value-of select="cbc:BrandName"/>
                    </td>
                    <td>
                        <xsl:value-of select="cbc:LicensePlateID"/>
                    </td>
                    <td>
                        <xsl:value-of select="cbc:TransportAuthorizationCode"/>
                    </td>
                </tr>
            </xsl:for-each>
        </table>
    </xsl:template>
    <!-- template del conductor -->
    <xsl:template name="conductor">
        <table>
            <tr class="beta">
                <td>Nro.</td>
                <td>Tipo doc.</td>
                <td>Nro docu</td>
                <td>Licencia</td>
                <td>Nombres y apellidos</td>
            </tr>
            <xsl:for-each select="sac:SUNATShipment/sac:SUNATShipmentStage/sac:SUNATTransportMeans/sac:DriverParty">
                <tr>
                    <td>
                        <xsl:value-of select="position()"/>
                    </td>
                    <!--<td><xsl:value-of select="cbc:AdditionalAccountID"/></td> -->
                    <td>
                        <xsl:call-template name="TipoDocIdentidad">
                            <xsl:with-param name="TipoDocIdentidad"
                                            select="cbc:AdditionalAccountID"/>
                        </xsl:call-template>
                    </td>
                    <td>
                        <xsl:value-of select="cbc:CustomerAssignedAccountID"/>
                    </td>
                    <td>
                        <xsl:value-of select="cac:Party/cac:PartyIdentification/cbc:ID"/>
                    </td>
                    <td>
                        <xsl:value-of select="cac:Party/cac:PartyName/cbc:Name"/>
                    </td>
                </tr>
            </xsl:for-each>
        </table>
    </xsl:template>
    <!-- template del detalle de CPE CreditNoteLine -->
    <xsl:template name="detalle">
        <table>
            <tr class="beta">
                <td>Cantidad</td>
                <td>Unid Medida</td>
                <td>Código</td>
                <td>Descripción</td>
                <td>Valor Unitario</td>
				<xsl:if test="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID=7152]/cbc:TaxAmount">
				<td>ICBPER</td>
				</xsl:if>
            </tr>
            <xsl:for-each select="cac:CreditNoteLine">
                <tr>
                    <td>
                        <xsl:value-of select="cbc:CreditedQuantity"/>
                    </td>
                    <td>
                        <xsl:call-template name="UnidadMedidaCatalogo">
                            <xsl:with-param name="UnidadMedida"
                                            select="cbc:CreditedQuantity/@unitCode"/>
                        </xsl:call-template>
                    </td>
                    <td>
                        <xsl:value-of select="cac:Item/cac:SellersItemIdentification/cbc:ID"/>
                    </td>
                    <td>
                        <xsl:value-of select="cac:Item/cbc:Description"/>
                    </td>
                    <td>
                        <xsl:value-of select="format-number(cac:Price/cbc:PriceAmount, '#,##0.00')"/>
                    </td>
					
					<xsl:if test="../cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID=7152]/cbc:TaxAmount">
					<xsl:choose>
					<xsl:when test="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID=7152]/cbc:TaxAmount">
					<td>
                        <xsl:value-of select="format-number(cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID=7152]/cbc:TaxAmount, '#,##0.00')"/>
                    </td>
					</xsl:when>
					<xsl:otherwise>
					<td>
						0.00
					</td>
					</xsl:otherwise>
					</xsl:choose>
					</xsl:if>
					
                </tr>
            </xsl:for-each>
        </table>
    </xsl:template>
    <!-- template de los bienes -->
    <xsl:template name="bienes">
        <table>
            <tr class="beta">
                <td>Nro</td>
                <td width="22%">Cod. bien</td>
                <td>Descripción detallada</td>
                <td>Unidad de Medida</td>
                <td>Cantidad</td>
                <td>Peso Neto</td>
                <td>Peso total</td>
            </tr>
            <xsl:for-each select="sac:SUNATDespatchLine">
                <tr>
                    <td>
                        <xsl:value-of select="position()"/>
                    </td>
                    <td>
                        <xsl:value-of select="cac:Item/cac:SellersItemIdentification/cbc:ExtendedID"/>
                    </td>
                    <td>
                        <xsl:value-of select="cac:Item/cbc:Description"/>
                    </td>
                    <td align="center">
                        <xsl:value-of select="cbc:NetWeightMeasure/@unitCode"/>
                    </td>
                    <td align="right">
                        <xsl:value-of select="cbc:DeliveredQuantity"/>
                    </td>
                    <td align="right">
                        <xsl:value-of select="cbc:NetWeightMeasure"/>
                    </td>
                    <td align="right">
                        <xsl:value-of select="format-number((cbc:DeliveredQuantity * cbc:NetWeightMeasure), '#.00')"/>
                    </td>
                </tr>
            </xsl:for-each>
        </table>
        <label>Peso Neto Total de la Guía:</label>
        <xsl:variable name="netoNoRound">
            <xsl:call-template name="addSubtotalNeto">
                <xsl:with-param name="Items"
                                select="sac:SUNATDespatchLine"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:value-of select="format-number($netoNoRound, '#.00')"/>
        <br/>
        <label>Peso Bruto Total de la Guía:</label>
        <xsl:variable name="brutoNoRound">
            <xsl:call-template name="addSubtotalBruto">
                <xsl:with-param name="Items"
                                select="sac:SUNATDespatchLine"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:value-of select="format-number($brutoNoRound, '#.00')"/>
        <br/>
    </xsl:template>
    <!-- template de la ruta fiscal -->
    <xsl:template name="rutaFiscal">
        <xsl:for-each select="sac:SUNATFiscalPath">
            <xsl:value-of select="cbc:ID"/> - <xsl:value-of select="cbc:Name"/>
            <br/>
        </xsl:for-each>
    </xsl:template>
    <!-- template del contribuyente -->
    <xsl:template name="contribuyente">
        <xsl:param name="Contribuyente"/>
        <label>Apellidos y nombres, denominación o razón social:</label>
        <xsl:value-of select="$Contribuyente/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName"/>
        <br/>
        <xsl:choose>
            <xsl:when test="$Contribuyente/cbc:AdditionalAccountID = 6">
                <label>Número de RUC:</label>
            </xsl:when>
            <xsl:otherwise>
                <label>Documento de identidad:</label>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:value-of select="$Contribuyente/cbc:CustomerAssignedAccountID"/>
    </xsl:template>
    <!-- template de la direccion -->
    <xsl:template name="direccion">
        <xsl:param name="Address"/>
        <xsl:if test="$Address/cbc:StreetName">
            <xsl:value-of select="$Address/cbc:StreetName"/>, 
        </xsl:if>
        <xsl:call-template name="ubigeo">
            <xsl:with-param name="Address"
                            select="$Address"/>
        </xsl:call-template>
    </xsl:template>
    <!-- template del ubigeo -->
    <xsl:template name="ubigeo">
        <xsl:param name="Address"/>
        <xsl:if test="$Address/cbc:CountrySubentity">
            <xsl:value-of select="$Address/cbc:CountrySubentity"/> 	-
        </xsl:if>
        <xsl:if test="$Address/cbc:CityName">
            <xsl:value-of select="$Address/cbc:CityName"/> -
        </xsl:if>
        <xsl:if test="$Address/cbc:District">
            <xsl:value-of select="$Address/cbc:District"/>
        </xsl:if>
    </xsl:template>
    <!-- Template motivo de traslado -->
    <xsl:template name="modalidadTraslado">
        <xsl:choose>
            <xsl:when test="cbc:TransportModeCode = 1"><!-- si es publico -->
                Público
            </xsl:when>
            <xsl:otherwise><!-- si es privado -->
                Privado
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <!-- Template motivo de traslado -->
    <xsl:template name="motivoTraslado">
        <xsl:choose>
            <xsl:when test="sac:TransportReasonCode = 1">
                1 - VENTA - VENTA CON ENTREGA A TERCEROS
            </xsl:when>
            <xsl:when test="sac:TransportReasonCode = 2">
                2 - COMPRA
            </xsl:when>
            <xsl:when test="sac:TransportReasonCode = 3">
                3 - DEVOLUCIÓN
            </xsl:when>
            <xsl:when test="sac:TransportReasonCode = 4">
                4 - TRASLADO ENTRE ESTABLECIMIENTOS DE LA MISMA EMPRESA
            </xsl:when>
            <xsl:when test="sac:TransportReasonCode = 5">
                5 - TRASLADO DE BIENES PARA PRODUCCIÓN
            </xsl:when>
            <xsl:when test="sac:TransportReasonCode = 6">
                6 - TRASLADO DE BIENES PARA MANIPULACIÓN
            </xsl:when>
            <xsl:when test="sac:TransportReasonCode = 7">
                7 - RECOJO DE BIENES
            </xsl:when>
            <xsl:when test="sac:TransportReasonCode = 8">
                8 - IMPORTACIÓN
            </xsl:when>
            <xsl:when test="sac:TransportReasonCode = 9">
                9 - EXPORTACIÓN
            </xsl:when>
            <xsl:when test="sac:TransportReasonCode = 10">
                10 - VENTA A DESTINATARIO NO INSCRITO EN EL REGISTRO
            </xsl:when>
            <xsl:when test="sac:TransportReasonCode = 11">
                11 - PRESTACIÓN DE SERVICIOS
            </xsl:when>
            <xsl:when test="sac:TransportReasonCode = 12">
                12 - NUEVA EMISIÓN POR CAMBIO DE DESTINATARIO
            </xsl:when>
            <xsl:when test="sac:TransportReasonCode = 13">
                13 - OTROS MOTIVOS
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="sac:TransportReasonCode"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <!-- Template motivo de emision de complementaria -->
    <xsl:template name="motivoEmision">
        <xsl:choose>
            <xsl:when test="sac:DespatchChangeReason = 1">
                1 - IMPOSIBILIDAD DE ARRIBO
            </xsl:when>
            <xsl:when test="sac:DespatchChangeReason = 2">
                2 - RETORNO DE BIENES
            </xsl:when>
            <xsl:when test="sac:DespatchChangeReason = 3">
                3 - TRANSBORDO
            </xsl:when>
            <xsl:when test="sac:DespatchChangeReason = 4">
                4 - IMPOSIBILIDAD DE ARRIBO CON TRANSBORDO
            </xsl:when>
            <xsl:when test="sac:DespatchChangeReason = 5">
                5 - RETORNO DE BIENES CON TRANSBORDO
            </xsl:when>
            <xsl:otherwise>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <!-- Template tipo de medio de transporte -->
    <xsl:template name="TipoVehiculo">
        <xsl:param name="TipoVehiculo"/>
        <xsl:choose>
            <xsl:when test="$TipoVehiculo = 1">
                MARITIMO
            </xsl:when>
            <xsl:when test="$TipoVehiculo = 2">
                FLUVIAL
            </xsl:when>
            <xsl:when test="$TipoVehiculo = 3">
                LACUSTRE
            </xsl:when>
            <xsl:when test="$TipoVehiculo = 4">
                AEREA
            </xsl:when>
            <xsl:when test="$TipoVehiculo = 6">
                FERROVIARIA
            </xsl:when>
            <xsl:when test="$TipoVehiculo = 7">
                CARRETERA
            </xsl:when>
            <xsl:otherwise>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <!-- Template tipo de documento de identidad -->
    <xsl:template name="TipoDocIdentidad">
        <xsl:param name="TipoDocIdentidad"/>
        <xsl:choose>
            <xsl:when test="$TipoDocIdentidad = '0'">
                DT.S/RUC
            </xsl:when>
            <xsl:when test="$TipoDocIdentidad = '1'">
                DNI
            </xsl:when>
            <xsl:when test="$TipoDocIdentidad = '4'">
                C. EXT.
            </xsl:when>
            <xsl:when test="$TipoDocIdentidad = '6'">
                RUC
            </xsl:when>
            <xsl:when test="$TipoDocIdentidad = '7'">
                PASAPORTE
            </xsl:when>
            <xsl:when test="$TipoDocIdentidad = 'A'">
                CED.DIPL.
            </xsl:when>
            <xsl:otherwise>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <!-- Template tipo de Unidad de Medida -->
    <xsl:template name="UnidadMedidaCatalogo">
        <xsl:param name="UnidadMedida"/>
        <xsl:choose>
            <xsl:when test="$UnidadMedida = 'NIU'">Unidad</xsl:when>
            <xsl:when test="$UnidadMedida = 'ZZ'">Unidad</xsl:when>
            <xsl:when test="$UnidadMedida = 'TON'">Tonelada</xsl:when>
            <xsl:otherwise>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <!-- Template simbolo de Moneda-->
    <xsl:template name="SimboloMonedaCatalogo">
        <xsl:param name="SimboloMoneda"/>
        <xsl:choose>
            <xsl:when test="$SimboloMoneda = 'PEN'">S/</xsl:when>
            <xsl:when test="$SimboloMoneda = 'USD'">&#36;</xsl:when>
            <xsl:when test="$SimboloMoneda = 'EUR'">&#8364;</xsl:when>
            <xsl:when test="$SimboloMoneda = 'XEU'">&#8364;</xsl:when>
            <xsl:when test="$SimboloMoneda = 'CAD'">C&#36;</xsl:when>
            <xsl:when test="$SimboloMoneda = 'GBP'">&#163;</xsl:when>
            <xsl:when test="$SimboloMoneda = 'JPY'">&#165;</xsl:when>
            <xsl:when test="$SimboloMoneda = 'SEK'">&#83;&#69;&#75;</xsl:when>
            <xsl:when test="$SimboloMoneda = 'CHF'">&#83;&#119;&#70;</xsl:when>

            <xsl:otherwise>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- Template Nombre Moneda -->
    <xsl:template name="MonedaCatalogo">
        <xsl:param name="SimboloMoneda"/>
        <xsl:choose>
            <xsl:when test="$SimboloMoneda = 'PEN'">SOLES</xsl:when>
            <xsl:when test="$SimboloMoneda = 'USD'">DOLARES</xsl:when>
            <xsl:when test="$SimboloMoneda = 'EUR'">EUROS</xsl:when>
            <xsl:when test="$SimboloMoneda = 'XEU'">EUROS</xsl:when>
            <xsl:when test="$SimboloMoneda = 'CAD'">DOLAR CANADIENSE</xsl:when>
            <xsl:when test="$SimboloMoneda = 'GBP'">LIBRA ESTERLINA/</xsl:when>
            <xsl:when test="$SimboloMoneda = 'JPY'">YEN/</xsl:when>
            <xsl:when test="$SimboloMoneda = 'SEK'">CORONA SUECA</xsl:when>
            <xsl:when test="$SimboloMoneda = 'CHF'">FRANCO SUIZO</xsl:when>
            <xsl:otherwise>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>   
    <!-- Template tipo de DocumentType -->
    <xsl:template name="DocumentTypeCatalogo">
        <xsl:param name="DocumentTypeCode"/>
        <xsl:choose>
            <xsl:when test="$DocumentTypeCode = '01'">Factura para corregir error en el RUC</xsl:when>
            <xsl:when test="$DocumentTypeCode = '02'">Factura Anticipo</xsl:when>
            <xsl:when test="$DocumentTypeCode = '03'">Boleta Anticipo</xsl:when>
            <xsl:when test="$DocumentTypeCode = '04'">Ticket</xsl:when>
            <xsl:when test="$DocumentTypeCode = '05'">Código SCOP</xsl:when>
            <xsl:when test="$DocumentTypeCode = '99'">Otros</xsl:when>            
            <xsl:otherwise>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <!-- Template recursivo para obtener suma total peso bruto-->
    <xsl:template name="addSubtotalBruto">
        <xsl:param name="Items"/>
        <xsl:variable name="Item1"
                      select="$Items[1]"/>
        <xsl:variable name="RemainingItems"
                      select="$Items[position() &gt; 1]"/>
        <xsl:variable name="subtotal"
                      select="$Item1/cbc:DeliveredQuantity * $Item1/cbc:GrossWeightMeasure"/>
        <xsl:choose>
            <xsl:when test="$RemainingItems">
                <xsl:variable name="subtotals">
                    <xsl:call-template name="addSubtotalBruto">
                        <xsl:with-param name="Items"
                                        select="$RemainingItems"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:value-of select="$subtotal + $subtotals"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$subtotal"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <!-- Template recursivo para obtener suma total peso neto-->
    <xsl:template name="addSubtotalNeto">
        <xsl:param name="Items"/>
        <xsl:variable name="Item1"
                      select="$Items[1]"/>
        <xsl:variable name="RemainingItems"
                      select="$Items[position() &gt; 1]"/>
        <xsl:variable name="subtotal"
                      select="$Item1/cbc:DeliveredQuantity * $Item1/cbc:NetWeightMeasure"/>
        <xsl:choose>
            <xsl:when test="$RemainingItems">
                <xsl:variable name="subtotals">
                    <xsl:call-template name="addSubtotalNeto">
                        <xsl:with-param name="Items"
                                        select="$RemainingItems"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:value-of select="$subtotal + $subtotals"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$subtotal"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
</xsl:stylesheet>
